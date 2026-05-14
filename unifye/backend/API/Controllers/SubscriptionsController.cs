// =============================================================================
// UniFye.API — SubscriptionsController
// File: API/Controllers/SubscriptionsController.cs
// =============================================================================

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniFye.Application.Subscriptions;
using UniFye.Application.Subscriptions.Dtos;
using UniFye.Domain.Subscriptions.Enums;

namespace UniFye.API.Controllers;

[ApiController]
[Route("api/subscriptions")]
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
    /// <summary>Returns all active subscription plans for the pricing/change plan UI.</summary>
    [HttpGet("plans")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(IReadOnlyList<SubscriptionPlanDto>), 200)]
    public async Task<IActionResult> GetAllPlans(CancellationToken ct)
    {
        var plans = await _subscriptionService.GetAllPlansAsync(ct);
        var dtos = plans.Select(MapPlanToDto).ToList();
        return Ok(dtos);
    }

    // ─── GET /api/subscriptions/me ────────────────────────────────────────────
    /// <summary>Returns the authenticated user's current subscription and resolved permissions.</summary>
    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(UserSubscriptionDto), 200)]
    public async Task<IActionResult> GetMySubscription(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
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
    /// <summary>Creates a Stripe Checkout Session for a plan upgrade. Returns the checkout URL.</summary>
    [HttpPost("checkout")]
    [Authorize]
    [ProducesResponseType(typeof(CheckoutSessionDto), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> CreateCheckout(
        [FromBody] CreateCheckoutSessionRequest request,
        CancellationToken ct)
    {
        if (!Enum.TryParse<SubscriptionTier>(request.TargetTier, ignoreCase: true, out var tier))
            return BadRequest(new { error = $"Invalid subscription tier: {request.TargetTier}" });

        if (tier == SubscriptionTier.Free)
            return BadRequest(new { error = "Cannot create a checkout session for the Free tier." });

        var userId = GetCurrentUserId();

        var checkoutUrl = await _subscriptionService.CreateCheckoutSessionAsync(
            userId,
            tier,
            request.IsAnnual,
            request.SuccessUrl,
            request.CancelUrl,
            ct);

        return Ok(new CheckoutSessionDto(checkoutUrl));
    }

    // ─── POST /api/subscriptions/billing-portal ───────────────────────────────
    /// <summary>Creates a Stripe Billing Portal session for managing payment methods / cancellation.</summary>
    [HttpPost("billing-portal")]
    [Authorize]
    [ProducesResponseType(typeof(BillingPortalSessionDto), 200)]
    public async Task<IActionResult> CreateBillingPortal(
        [FromBody] CreateBillingPortalRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var portalUrl = await _subscriptionService.CreateBillingPortalSessionAsync(userId, request.ReturnUrl, ct);
        return Ok(new BillingPortalSessionDto(portalUrl));
    }

    // ─── POST /api/subscriptions/webhook ──────────────────────────────────────
    /// <summary>Stripe webhook receiver. Must be excluded from JWT auth middleware.</summary>
    [HttpPost("webhook")]
    [AllowAnonymous]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> StripeWebhook(CancellationToken ct)
    {
        string json;
        using (var reader = new StreamReader(HttpContext.Request.Body))
        {
            json = await reader.ReadToEndAsync(ct);
        }

        var signature = Request.Headers["Stripe-Signature"].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(signature))
            return BadRequest(new { error = "Missing Stripe-Signature header." });

        try
        {
            await _subscriptionService.HandleStripeWebhookAsync(json, signature, ct);
            return Ok();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to process Stripe webhook");
            return BadRequest(new { error = "Webhook processing failed." });
        }
    }

    // ─── GET /api/subscriptions/permission/{gate} ─────────────────────────────
    /// <summary>Checks if the current user can perform a specific gated action.</summary>
    [HttpGet("permission/{gate}")]
    [Authorize]
    [ProducesResponseType(typeof(object), 200)]
    public async Task<IActionResult> CheckPermission(string gate, CancellationToken ct)
    {
        if (!Enum.TryParse<PermissionGate>(gate, ignoreCase: true, out var permissionGate))
            return BadRequest(new { error = $"Unknown permission gate: {gate}" });

        var userId = GetCurrentUserId();
        var allowed = await _subscriptionService.CanUserPerformActionAsync(userId, permissionGate, ct);

        return Ok(new { gate = gate, allowed });
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    private Guid GetCurrentUserId()
    {
        var claim = User.FindFirst("sub") ?? User.FindFirst("id");
        if (claim is null || !Guid.TryParse(claim.Value, out var userId))
            throw new UnauthorizedAccessException("User ID claim not found in token.");
        return userId;
    }

    private static SubscriptionPlanDto MapPlanToDto(Domain.Subscriptions.Entities.SubscriptionPlan plan) =>
        new(
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
            plan.Permissions is not null ? MapPermissionsToDto(plan.Permissions) : new PlanPermissionsDto(
                10, 3, false, false, false, false, 0, false,
                1, false, 0, 0, false, 0, false, false, false, false,
                "none", false, 1, false, false, false, false, false, 10
            )
        );

    private static PlanPermissionsDto MapPermissionsToDto(Domain.Subscriptions.Entities.PlanFeaturePermissions p) =>
        new(
            p.DailySwipeLimit, p.MaxActiveMatches, p.CanSeeWhoLikedMe,
            p.CanSendMedia, p.CanSendVoiceNotes, p.HasReadReceipts,
            p.WeeklyProfileBoostCount, p.HasVerifiedOrganiserBadge,
            p.MaxJoinedCommunities, p.CanCreateCommunity, p.MaxOwnedCommunities, p.CommunityMemberCap,
            p.CanCreateEvents, p.MonthlyEventLimit,
            p.CanGenerateQrCheckin, p.CanExportAttendees, p.CanPinAnnouncements, p.EventsPriorityListing,
            p.AnalyticsAccess.ToString().ToLower(), p.CanExportAnalyticsPdf,
            p.MaxAccountAdmins, p.CanBroadcastMessages, p.HasWebhookAccess,
            p.HasWhiteLabel, p.HasSlaSupport, p.HasDedicatedManager,
            p.LeaderboardVisibilityCap
        );
}
