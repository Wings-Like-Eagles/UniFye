// =============================================================================
// UniFye.Application — ISubscriptionService Interface
// File: Application/Subscriptions/ISubscriptionService.cs
// =============================================================================

using UniFye.Domain.Subscriptions.Entities;
using UniFye.Domain.Subscriptions.Enums;

namespace UniFye.Application.Subscriptions;

/// <summary>
/// Core subscription service interface.
/// Handles plan retrieval, permission resolution, and Stripe checkout orchestration.
/// </summary>
public interface ISubscriptionService
{
    /// <summary>Gets all active subscription plans for display in pricing UI.</summary>
    Task<IReadOnlyList<SubscriptionPlan>> GetAllPlansAsync(CancellationToken ct = default);

    /// <summary>Gets the full plan definition including permissions by tier.</summary>
    Task<SubscriptionPlan?> GetPlanByTierAsync(SubscriptionTier tier, CancellationToken ct = default);

    /// <summary>Gets the current subscription for a user. Returns Free tier record if none exists.</summary>
    Task<UserSubscription> GetUserSubscriptionAsync(Guid userId, CancellationToken ct = default);

    /// <summary>Resolves the merged feature permissions for a user based on their active plan.</summary>
    Task<PlanFeaturePermissions> GetUserPermissionsAsync(Guid userId, CancellationToken ct = default);

    /// <summary>
    /// Creates a Stripe Checkout Session URL for a plan upgrade.
    /// Returns the Stripe-hosted checkout URL to redirect the user to.
    /// </summary>
    Task<string> CreateCheckoutSessionAsync(
        Guid userId,
        SubscriptionTier targetTier,
        bool isAnnual,
        string successUrl,
        string cancelUrl,
        CancellationToken ct = default);

    /// <summary>Creates a Stripe Customer Portal session URL for billing management.</summary>
    Task<string> CreateBillingPortalSessionAsync(Guid userId, string returnUrl, CancellationToken ct = default);

    /// <summary>Processes incoming Stripe webhook events to update subscription state.</summary>
    Task HandleStripeWebhookAsync(string stripeEventJson, string stripeSignature, CancellationToken ct = default);

    /// <summary>Downgrades user to Free tier (e.g. on payment failure after grace period).</summary>
    Task DowngradeToFreeAsync(Guid userId, string reason, CancellationToken ct = default);

    /// <summary>Checks if a user has permission for a specific feature gate.</summary>
    Task<bool> CanUserPerformActionAsync(Guid userId, PermissionGate gate, CancellationToken ct = default);
}

/// <summary>
/// Discrete feature gates used to check permissions at the controller/service layer.
/// Use these instead of raw boolean property checks to ensure consistent permission logic.
/// </summary>
public enum PermissionGate
{
    // Swipe & Match
    Swipe,
    ViewMatch,
    SeeWhoLikedMe,

    // Messaging
    SendMedia,
    SendVoiceNote,

    // Profile
    UseProfileBoost,

    // Communities
    JoinCommunity,
    CreateCommunity,
    OwnCommunity,

    // Events
    CreateEvent,
    GenerateQrCheckin,
    ExportAttendees,
    PinAnnouncement,

    // Analytics
    ViewBasicAnalytics,
    ViewAdvancedAnalytics,
    ExportAnalyticsPdf,

    // Enterprise
    BroadcastMessage,
    AccessWebhooks,
    UseWhiteLabel
}
