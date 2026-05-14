// =============================================================================
// UniFye.Application — SubscriptionDTOs
// File: Application/Subscriptions/Dtos/SubscriptionDtos.cs
// Response/Request DTOs used by the API controller layer.
// =============================================================================

using UniFye.Domain.Subscriptions.Enums;

namespace UniFye.Application.Subscriptions.Dtos;

// ─── Response DTOs ────────────────────────────────────────────────────────────

/// <summary>Full plan card response — used for the pricing/change plan screen.</summary>
public record SubscriptionPlanDto(
    Guid Id,
    string Tier,
    string DisplayName,
    string? Description,
    string? BadgeLabel,
    string? BadgeColourHex,
    decimal MonthlyPriceZar,
    decimal? AnnualPriceZar,
    bool IsActive,
    int SortOrder,
    PlanPermissionsDto Permissions
);

/// <summary>Flattened permission snapshot returned to the Flutter client.</summary>
public record PlanPermissionsDto(
    int DailySwipeLimit,
    int MaxActiveMatches,
    bool CanSeeWhoLikedMe,
    bool CanSendMedia,
    bool CanSendVoiceNotes,
    bool HasReadReceipts,
    int WeeklyProfileBoostCount,
    bool HasVerifiedOrganiserBadge,
    int MaxJoinedCommunities,
    bool CanCreateCommunity,
    int MaxOwnedCommunities,
    int CommunityMemberCap,
    bool CanCreateEvents,
    int MonthlyEventLimit,
    bool CanGenerateQrCheckin,
    bool CanExportAttendees,
    bool CanPinAnnouncements,
    bool EventsPriorityListing,
    string AnalyticsAccess,
    bool CanExportAnalyticsPdf,
    int MaxAccountAdmins,
    bool CanBroadcastMessages,
    bool HasWebhookAccess,
    bool HasWhiteLabel,
    bool HasSlaSupport,
    bool HasDedicatedManager,
    int LeaderboardVisibilityCap
);

/// <summary>User's current subscription state — used for profile/settings screen.</summary>
public record UserSubscriptionDto(
    string Tier,
    string Status,
    bool IsAnnualBilling,
    DateTimeOffset? CurrentPeriodEnd,
    bool CancelAtPeriodEnd,
    bool IsPendingCancellation,
    bool IsTrialing,
    DateTimeOffset? TrialEnd,
    int? DaysRemainingInPeriod,
    bool IsAccessible,
    PlanPermissionsDto Permissions
);

/// <summary>Stripe checkout session response.</summary>
public record CheckoutSessionDto(string CheckoutUrl);

/// <summary>Stripe billing portal session response.</summary>
public record BillingPortalSessionDto(string PortalUrl);

// ─── Request DTOs ─────────────────────────────────────────────────────────────

/// <summary>Request body for initiating a plan upgrade checkout.</summary>
public record CreateCheckoutSessionRequest(
    string TargetTier,    // e.g. "plus", "community_pro", "campus_enterprise"
    bool IsAnnual,
    string SuccessUrl,
    string CancelUrl
);

/// <summary>Request body for opening the Stripe billing portal.</summary>
public record CreateBillingPortalRequest(string ReturnUrl);
