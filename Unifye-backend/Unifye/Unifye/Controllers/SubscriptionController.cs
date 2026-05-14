using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Unifye.Enums;
using Unifye.Models;
using Unifye.Services;
using static Unifye.DTOs.SubscriptionDtos;

namespace Unifye.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class SubscriptionsController : ControllerBase
    {
        private readonly ISubscriptionService _subscriptionService;
        private readonly ILogger<SubscriptionsController> _logger;

        public SubscriptionsController(
            ISubscriptionService subscriptionService,
            ILogger<SubscriptionsController> logger)
        {
            _subscriptionService = subscriptionService;
            _logger = logger;
        }

        // ─── GET /api/subscriptions/plans ─────────────────────────────────────────

        /// <summary>
        /// Returns all active subscription plans for the pricing/change plan UI.
        /// </summary>
        [HttpGet("plans")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(IReadOnlyList<SubscriptionPlanDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetAllPlans(CancellationToken ct)
        {
            var plans = await _subscriptionService.GetAllPlansAsync(ct);
            var dtos = plans.Select(MapPlanToDto).ToList();

            return Ok(dtos);
        }

        // ─── GET /api/subscriptions/me ────────────────────────────────────────────

        /// <summary>
        /// Returns the authenticated user's current subscription and resolved permissions.
        /// </summary>
        [HttpGet("me")]
        [Authorize]
        [ProducesResponseType(typeof(UserSubscriptionDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetMySubscription(CancellationToken ct)
        {
            if (!TryGetCurrentUserId(out var userId))
                return Unauthorized(new { error = "User ID claim not found in token." });

            var subscription = await _subscriptionService.GetUserSubscriptionAsync(userId, ct);
            var permissions = await _subscriptionService.GetUserPermissionsAsync(userId, ct);

            var dto = new UserSubscriptionDto(
                Tier: subscription.Tier.ToString(),
                Status: subscription.Status.ToString(),
                IsAnnualBilling: subscription.IsAnnualBilling,
                CurrentPeriodEnd: subscription.CurrentPeriodEnd,
                CancelAtPeriodEnd: subscription.CancelAtPeriodEnd,
                IsPendingCancellation: subscription.IsPendingCancellation,
                IsTrialing: subscription.IsTrialing,
                TrialEnd: subscription.TrialEnd,
                DaysRemainingInPeriod: subscription.DaysRemainingInPeriod,
                IsAccessible: subscription.IsAccessible,
                Permissions: MapPermissionsToDto(permissions)
            );

            return Ok(dto);
        }

        // ─── POST /api/subscriptions/checkout ─────────────────────────────────────

        /// <summary>
        /// Creates a Stripe Checkout Session for a plan upgrade.
        /// Returns the checkout URL.
        /// </summary>
        [HttpPost("checkout")]
        [Authorize]
        [ProducesResponseType(typeof(CheckoutSessionDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> CreateCheckout(
            [FromBody] CreateCheckoutSessionRequest request,
            CancellationToken ct)
        {
            if (!Enum.TryParse<SubscriptionTier>(
                    request.TargetTier,
                    ignoreCase: true,
                    out var tier))
            {
                return BadRequest(new
                {
                    error = $"Invalid subscription tier: {request.TargetTier}"
                });
            }

            if (tier == SubscriptionTier.Free)
            {
                return BadRequest(new
                {
                    error = "Cannot create a checkout session for the Free tier."
                });
            }

            if (!TryGetCurrentUserId(out var userId))
                return Unauthorized(new { error = "User ID claim not found in token." });

            var checkoutUrl = await _subscriptionService.CreateCheckoutSessionAsync(
                userId,
                tier,
                request.IsAnnual,
                request.SuccessUrl,
                request.CancelUrl,
                ct
            );

            return Ok(new CheckoutSessionDto(checkoutUrl));
        }

        // ─── POST /api/subscriptions/billing-portal ───────────────────────────────

        /// <summary>
        /// Creates a Stripe Billing Portal session for managing payment methods/cancellation.
        /// </summary>
        [HttpPost("billing-portal")]
        [Authorize]
        [ProducesResponseType(typeof(BillingPortalSessionDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> CreateBillingPortal(
            [FromBody] CreateBillingPortalRequest request,
            CancellationToken ct)
        {
            if (!TryGetCurrentUserId(out var userId))
                return Unauthorized(new { error = "User ID claim not found in token." });

            var portalUrl = await _subscriptionService.CreateBillingPortalSessionAsync(
                userId,
                request.ReturnUrl,
                ct
            );

            return Ok(new BillingPortalSessionDto(portalUrl));
        }

        // ─── POST /api/subscriptions/webhook ──────────────────────────────────────

        /// <summary>
        /// Stripe webhook receiver.
        /// Must be excluded from JWT auth middleware.
        /// </summary>
        [HttpPost("webhook")]
        [AllowAnonymous]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> StripeWebhook(CancellationToken ct)
        {
            string json;

            using (var reader = new StreamReader(HttpContext.Request.Body))
            {
                json = await reader.ReadToEndAsync();
            }

            var signature = Request.Headers["Stripe-Signature"].FirstOrDefault();

            if (string.IsNullOrWhiteSpace(signature))
            {
                return BadRequest(new
                {
                    error = "Missing Stripe-Signature header."
                });
            }

            try
            {
                await _subscriptionService.HandleStripeWebhookAsync(
                    json,
                    signature,
                    ct
                );

                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process Stripe webhook");

                return BadRequest(new
                {
                    error = "Webhook processing failed."
                });
            }
        }

        // ─── GET /api/subscriptions/permission/{gate} ─────────────────────────────

        /// <summary>
        /// Checks if the current user can perform a specific gated action.
        /// </summary>
        [HttpGet("permission/{gate}")]
        [Authorize]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> CheckPermission(
            string gate,
            CancellationToken ct)
        {
            if (!Enum.TryParse<PermissionGate>(
                    gate,
                    ignoreCase: true,
                    out var permissionGate))
            {
                return BadRequest(new
                {
                    error = $"Unknown permission gate: {gate}"
                });
            }

            if (!TryGetCurrentUserId(out var userId))
                return Unauthorized(new { error = "User ID claim not found in token." });

            var allowed = await _subscriptionService.CanUserPerformActionAsync(
                userId,
                permissionGate,
                ct
            );

            return Ok(new
            {
                gate,
                allowed
            });
        }

        // ─── Private Helpers ──────────────────────────────────────────────────────

        private bool TryGetCurrentUserId(out Guid userId)
        {
            userId = Guid.Empty;

            var claim = User.FindFirst("sub") ?? User.FindFirst("id");

            return claim is not null &&
                   Guid.TryParse(claim.Value, out userId);
        }

        private static SubscriptionPlanDto MapPlanToDto(
            SubscriptionPlan plan)
        {
            return new SubscriptionPlanDto(
                plan.Id,
                plan.Tier.ToString(),
                plan.DisplayName,
                plan.Description,
                plan.BadgeLabel,
                plan.BadgeColourHex,
                plan.MonthlyPriceZar,
                plan.AnnualPriceZar,
                plan.IsActive,
                plan.SortOrder,
               MapPermissionsToDto(plan.Permissions)
            );
        }

        private static PlanPermissionsDto MapPermissionsToDto(
            PlanFeaturePermissions p)
        {
            return new PlanPermissionsDto(
                p.DailySwipeLimit,
                p.MaxActiveMatches,
                p.CanSeeWhoLikedMe,
                p.CanSendMedia,
                p.CanSendVoiceNotes,
                p.HasReadReceipts,
                p.WeeklyProfileBoostCount,
                p.HasVerifiedOrganiserBadge,
                p.MaxJoinedCommunities,
                p.CanCreateCommunity,
                p.MaxOwnedCommunities,
                p.CommunityMemberCap,
                p.CanCreateEvents,
                p.MonthlyEventLimit,
                p.CanGenerateQrCheckin,
                p.CanExportAttendees,
                p.CanPinAnnouncements,
                p.EventsPriorityListing,
                p.AnalyticsAccess.ToString().ToLower(),
                p.CanExportAnalyticsPdf,
                p.MaxAccountAdmins,
                p.CanBroadcastMessages,
                p.HasWebhookAccess,
                p.HasWhiteLabel,
                p.HasSlaSupport,
                p.HasDedicatedManager,
                p.LeaderboardVisibilityCap
            );
        }
    }
}
