using Unifye.Enums;
using Unifye.Models;

namespace Unifye.Services
{

    /// <summary>
    /// Implements subscription management including plan resolution,
    /// Stripe session creation, webhook processing, and permission gating.
    /// </summary>
    public class SubscriptionService : ISubscriptionService
    {
        private readonly ISubscriptionRepository _subscriptionRepository;
        private readonly IStripeService _stripeService;
        private readonly ILogger<SubscriptionService> _logger;

        // Cache of plan permissions keyed by tier — loaded once at startup
        private readonly Dictionary<SubscriptionTier, PlanFeaturePermissions> _permissionsCache = new();

        public SubscriptionService(
            ISubscriptionRepository subscriptionRepository,
            IStripeService stripeService,
            ILogger<SubscriptionService> logger)
        {
            _subscriptionRepository = subscriptionRepository;
            _stripeService = stripeService;
            _logger = logger;
        }

        // ─── Plan Retrieval ───────────────────────────────────────────────────────

        public async Task<IReadOnlyList<SubscriptionPlan>> GetAllPlansAsync(CancellationToken ct = default)
        {
            return await _subscriptionRepository.GetAllActivePlansAsync(ct);
        }

        public async Task<SubscriptionPlan?> GetPlanByTierAsync(SubscriptionTier tier, CancellationToken ct = default)
        {
            return await _subscriptionRepository.GetPlanByTierAsync(tier, ct);
        }

        // ─── User Subscription ────────────────────────────────────────────────────

        public async Task<UserSubscription> GetUserSubscriptionAsync(Guid userId, CancellationToken ct = default)
        {
            var subscription = await _subscriptionRepository.GetUserSubscriptionAsync(userId, ct);

            // Return a virtual Free subscription if none exists — no DB write needed
            if (subscription is null)
            {
                var freePlan = await _subscriptionRepository.GetPlanByTierAsync(SubscriptionTier.Free, ct)
                               ?? throw new InvalidOperationException("Free plan not seeded in database.");

                return new UserSubscription
                {
                    UserId = userId,
                    PlanId = freePlan.Id,
                    Tier = SubscriptionTier.Free,
                    Status = SubscriptionStatus.Active,
                    Plan = freePlan
                };
            }

            return subscription;
        }

        // ─── Permission Resolution ────────────────────────────────────────────────

        public async Task<PlanFeaturePermissions> GetUserPermissionsAsync(Guid userId, CancellationToken ct = default)
        {
            var subscription = await GetUserSubscriptionAsync(userId, ct);

            // If subscription is not accessible (e.g. past-due beyond grace), return Free permissions
            var effectiveTier = subscription.IsAccessible
                ? subscription.Tier
                : SubscriptionTier.Free;

            return await _subscriptionRepository.GetPermissionsForTierAsync(effectiveTier, ct)
                   ?? throw new InvalidOperationException($"No permissions found for tier {effectiveTier}");
        }

        public async Task<bool> CanUserPerformActionAsync(Guid userId, PermissionGate gate, CancellationToken ct = default)
        {
            var permissions = await GetUserPermissionsAsync(userId, ct);

            return gate switch
            {
                // Swipe & Match
                PermissionGate.Swipe => true,  // Swipe is always allowed; limit enforced separately
                PermissionGate.ViewMatch => true,  // Match viewing allowed; cap enforced separately
                PermissionGate.SeeWhoLikedMe => permissions.CanSeeWhoLikedMe,

                // Messaging
                PermissionGate.SendMedia => permissions.CanSendMedia,
                PermissionGate.SendVoiceNote => permissions.CanSendVoiceNotes,

                // Profile
                PermissionGate.UseProfileBoost => permissions.WeeklyProfileBoostCount != 0,

                // Communities
                PermissionGate.JoinCommunity => true,  // All can join; cap checked separately
                PermissionGate.CreateCommunity => permissions.CanCreateCommunity,
                PermissionGate.OwnCommunity => permissions.MaxOwnedCommunities != 0,

                // Events
                PermissionGate.CreateEvent => permissions.CanCreateEvents,
                PermissionGate.GenerateQrCheckin => permissions.CanGenerateQrCheckin,
                PermissionGate.ExportAttendees => permissions.CanExportAttendees,
                PermissionGate.PinAnnouncement => permissions.CanPinAnnouncements,

                // Analytics
                PermissionGate.ViewBasicAnalytics => permissions.HasAnyAnalyticsAccess,
                PermissionGate.ViewAdvancedAnalytics => permissions.HasAdvancedAnalytics,
                PermissionGate.ExportAnalyticsPdf => permissions.CanExportAnalyticsPdf,

                // Enterprise
                PermissionGate.BroadcastMessage => permissions.CanBroadcastMessages,
                PermissionGate.AccessWebhooks => permissions.HasWebhookAccess,
                PermissionGate.UseWhiteLabel => permissions.HasWhiteLabel,

                _ => false
            };
        }

        // ─── Stripe Checkout ──────────────────────────────────────────────────────

        public async Task<string> CreateCheckoutSessionAsync(
            Guid userId,
            SubscriptionTier targetTier,
            bool isAnnual,
            string successUrl,
            string cancelUrl,
            CancellationToken ct = default)
        {
            if (targetTier == SubscriptionTier.Free)
                throw new ArgumentException("Cannot create a checkout session for the Free tier.");

            var plan = await GetPlanByTierAsync(targetTier, ct)
                       ?? throw new InvalidOperationException($"Plan not found for tier {targetTier}");

            var priceId = isAnnual ? plan.StripeAnnualPriceId : plan.StripeMonthlyPriceId;
            if (string.IsNullOrWhiteSpace(priceId))
                throw new InvalidOperationException($"No Stripe price configured for {targetTier} ({(isAnnual ? "annual" : "monthly")}).");

            var subscription = await GetUserSubscriptionAsync(userId, ct);
            var stripeCustomerId = subscription.StripeCustomerId;

            // Create or reuse Stripe Customer
            if (string.IsNullOrWhiteSpace(stripeCustomerId))
            {
                stripeCustomerId = await _stripeService.CreateCustomerAsync(userId, ct);
                await _subscriptionRepository.UpdateStripeCustomerIdAsync(userId, stripeCustomerId, ct);
            }

            var checkoutUrl = await _stripeService.CreateCheckoutSessionAsync(
                stripeCustomerId,
                priceId,
                successUrl,
                cancelUrl,
                trialDays: subscription.IsFree ? 7 : 0,  // 7-day trial for first-time upgrades
                ct: ct);

            _logger.LogInformation(
                "Created Stripe checkout session for user {UserId} upgrading to {Tier} ({Billing})",
                userId, targetTier, isAnnual ? "annual" : "monthly");

            return checkoutUrl;
        }

        public async Task<string> CreateBillingPortalSessionAsync(Guid userId, string returnUrl, CancellationToken ct = default)
        {
            var subscription = await GetUserSubscriptionAsync(userId, ct);

            if (string.IsNullOrWhiteSpace(subscription.StripeCustomerId))
                throw new InvalidOperationException("User does not have a Stripe customer record.");

            return await _stripeService.CreateBillingPortalSessionAsync(
                subscription.StripeCustomerId, returnUrl, ct);
        }

        // ─── Stripe Webhook Processing ────────────────────────────────────────────

        public async Task HandleStripeWebhookAsync(string stripeEventJson, string stripeSignature, CancellationToken ct = default)
        {
            var (eventType, stripeEvent) = await _stripeService.ParseAndValidateWebhookAsync(
                stripeEventJson, stripeSignature, ct);

            // Idempotency check — skip if we've already processed this event
            if (await _subscriptionRepository.HasProcessedStripeEventAsync(stripeEvent.Id, ct))
            {
                _logger.LogInformation("Skipping duplicate Stripe event {EventId}", stripeEvent.Id);
                return;
            }

            _logger.LogInformation("Processing Stripe event {EventType} [{EventId}]", eventType, stripeEvent.Id);

            switch (eventType)
            {
                case "customer.subscription.created":
                case "customer.subscription.updated":
                    await HandleSubscriptionUpdatedAsync(stripeEvent, ct);
                    break;

                case "customer.subscription.deleted":
                    await HandleSubscriptionDeletedAsync(stripeEvent, ct);
                    break;

                case "invoice.payment_failed":
                    await HandlePaymentFailedAsync(stripeEvent, ct);
                    break;

                case "invoice.payment_succeeded":
                    await HandlePaymentSucceededAsync(stripeEvent, ct);
                    break;

                default:
                    _logger.LogDebug("Unhandled Stripe event type: {EventType}", eventType);
                    break;
            }
        }

        private async Task HandleSubscriptionUpdatedAsync(dynamic stripeEvent, CancellationToken ct)
        {
            var stripeSubId = (string)stripeEvent.Data.Object.Id;
            var customerId = (string)stripeEvent.Data.Object.Customer;
            var stripePriceId = (string)stripeEvent.Data.Object.Items.Data[0].Price.Id;
            var status = ParseStripeStatus((string)stripeEvent.Data.Object.Status);
            var periodEnd = DateTimeOffset.FromUnixTimeSeconds((long)stripeEvent.Data.Object.CurrentPeriodEnd);
            var periodStart = DateTimeOffset.FromUnixTimeSeconds((long)stripeEvent.Data.Object.CurrentPeriodStart);

            var tier = await _subscriptionRepository.GetTierByStripePriceIdAsync(stripePriceId, ct);
            var userId = await _subscriptionRepository.GetUserIdByStripeCustomerIdAsync(customerId, ct);

            if (userId is null)
            {
                _logger.LogWarning("No user found for Stripe customer {CustomerId}", customerId);
                return;
            }

            var plan = await _subscriptionRepository.GetPlanByTierAsync(tier, ct)!;
            var subscription = await _subscriptionRepository.GetUserSubscriptionAsync(userId.Value, ct);

            var previousTier = subscription?.Tier;
            var previousStatus = subscription?.Status;

            if (subscription is null)
            {
                subscription = new UserSubscription { UserId = userId.Value };
                await _subscriptionRepository.CreateUserSubscriptionAsync(subscription, ct);
            }

            subscription.Tier = tier;
            subscription.PlanId = plan!.Id;
            subscription.Status = status;
            subscription.StripeCustomerId = customerId;
            subscription.StripeSubscriptionId = stripeSubId;
            subscription.StripePriceId = stripePriceId;
            subscription.CurrentPeriodStart = periodStart;
            subscription.CurrentPeriodEnd = periodEnd;
            subscription.GracePeriodEnd = null; // Clear any grace period on successful update

            await _subscriptionRepository.UpdateUserSubscriptionAsync(subscription, ct);

            await _subscriptionRepository.RecordHistoryAsync(new SubscriptionHistory
            {
                UserId = userId.Value,
                SubscriptionId = subscription.Id,
                PreviousTier = previousTier,
                NewTier = tier,
                PreviousStatus = previousStatus,
                NewStatus = status,
                ChangeReason = "stripe_webhook",
                StripeEventId = (string)stripeEvent.Id
            }, ct);
        }

        private async Task HandleSubscriptionDeletedAsync(dynamic stripeEvent, CancellationToken ct)
        {
            var customerId = (string)stripeEvent.Data.Object.Customer;
            var userId = await _subscriptionRepository.GetUserIdByStripeCustomerIdAsync(customerId, ct);

            if (userId is null) return;

            await DowngradeToFreeAsync(userId.Value, "subscription_deleted", ct);

            await _subscriptionRepository.RecordHistoryAsync(new SubscriptionHistory
            {
                UserId = userId.Value,
                SubscriptionId = (await _subscriptionRepository.GetUserSubscriptionAsync(userId.Value, ct))!.Id,
                NewTier = SubscriptionTier.Free,
                NewStatus = SubscriptionStatus.Canceled,
                ChangeReason = "subscription_deleted",
                StripeEventId = (string)stripeEvent.Id
            }, ct);
        }

        private async Task HandlePaymentFailedAsync(dynamic stripeEvent, CancellationToken ct)
        {
            var customerId = (string)stripeEvent.Data.Object.Customer;
            var userId = await _subscriptionRepository.GetUserIdByStripeCustomerIdAsync(customerId, ct);

            if (userId is null) return;

            var subscription = await _subscriptionRepository.GetUserSubscriptionAsync(userId.Value, ct);
            if (subscription is null) return;

            // Set 3-day grace period before downgrade
            subscription.Status = SubscriptionStatus.PastDue;
            subscription.GracePeriodEnd = DateTimeOffset.UtcNow.AddDays(3);

            await _subscriptionRepository.UpdateUserSubscriptionAsync(subscription, ct);

            _logger.LogWarning(
                "Payment failed for user {UserId}. Grace period ends {GraceEnd}",
                userId.Value, subscription.GracePeriodEnd);
        }

        private async Task HandlePaymentSucceededAsync(dynamic stripeEvent, CancellationToken ct)
        {
            var customerId = (string)stripeEvent.Data.Object.Customer;
            var userId = await _subscriptionRepository.GetUserIdByStripeCustomerIdAsync(customerId, ct);

            if (userId is null) return;

            var subscription = await _subscriptionRepository.GetUserSubscriptionAsync(userId.Value, ct);
            if (subscription is null) return;

            subscription.Status = SubscriptionStatus.Active;
            subscription.GracePeriodEnd = null;

            await _subscriptionRepository.UpdateUserSubscriptionAsync(subscription, ct);
        }

        public async Task DowngradeToFreeAsync(Guid userId, string reason, CancellationToken ct = default)
        {
            var subscription = await _subscriptionRepository.GetUserSubscriptionAsync(userId, ct);
            if (subscription is null || subscription.Tier == SubscriptionTier.Free) return;

            var freePlan = await _subscriptionRepository.GetPlanByTierAsync(SubscriptionTier.Free, ct)!;

            subscription.Tier = SubscriptionTier.Free;
            subscription.PlanId = freePlan!.Id;
            subscription.Status = SubscriptionStatus.Canceled;
            subscription.StripeSubscriptionId = null;
            subscription.StripePriceId = null;
            subscription.CurrentPeriodStart = null;
            subscription.CurrentPeriodEnd = null;
            subscription.GracePeriodEnd = null;

            await _subscriptionRepository.UpdateUserSubscriptionAsync(subscription, ct);

            _logger.LogInformation("User {UserId} downgraded to Free. Reason: {Reason}", userId, reason);
        }

        // ─── Private Helpers ──────────────────────────────────────────────────────

        private static SubscriptionStatus ParseStripeStatus(string status) => status switch
        {
            "active" => SubscriptionStatus.Active,
            "trialing" => SubscriptionStatus.Trialing,
            "past_due" => SubscriptionStatus.PastDue,
            "canceled" => SubscriptionStatus.Canceled,
            "unpaid" => SubscriptionStatus.Unpaid,
            "paused" => SubscriptionStatus.Paused,
            _ => SubscriptionStatus.Active
        };
    }
}
