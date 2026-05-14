// =============================================================================
// UniFye.Domain — PlanFeaturePermissions Entity
// File: Domain/Subscriptions/Entities/PlanFeaturePermissions.cs
// Maps to PostgreSQL: plan_feature_permissions table
// Convention: -1 on INT fields = unlimited
// =============================================================================

using UniFye.Domain.Subscriptions.Enums;

namespace UniFye.Domain.Subscriptions.Entities;

/// <summary>
/// Concrete feature permission values for a subscription plan tier.
/// -1 on any integer field indicates "unlimited".
/// </summary>
public class PlanFeaturePermissions
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public Guid PlanId { get; init; }
    public SubscriptionTier Tier { get; init; }

    // ─── Swipe & Match ───────────────────────────────────────────────────────
    /// <summary>Max swipes per day. -1 = unlimited.</summary>
    public int DailySwipeLimit { get; init; } = 10;

    /// <summary>Max concurrent active matches. -1 = unlimited.</summary>
    public int MaxActiveMatches { get; init; } = 3;

    public bool CanSeeWhoLikedMe { get; init; } = false;

    // ─── Messaging ───────────────────────────────────────────────────────────
    public bool CanSendMedia { get; init; } = false;
    public bool CanSendVoiceNotes { get; init; } = false;
    public bool HasReadReceipts { get; init; } = false;

    // ─── Profile ─────────────────────────────────────────────────────────────
    /// <summary>Profile boosts allowed per week. -1 = unlimited.</summary>
    public int WeeklyProfileBoostCount { get; init; } = 0;
    public bool HasVerifiedOrganiserBadge { get; init; } = false;

    // ─── Communities ─────────────────────────────────────────────────────────
    /// <summary>Max community spaces the user can join. -1 = unlimited.</summary>
    public int MaxJoinedCommunities { get; init; } = 1;
    public bool CanCreateCommunity { get; init; } = false;
    /// <summary>How many communities the user can own/admin. -1 = unlimited.</summary>
    public int MaxOwnedCommunities { get; init; } = 0;
    /// <summary>Max members per owned community. -1 = unlimited.</summary>
    public int CommunityMemberCap { get; init; } = 0;

    // ─── Events ──────────────────────────────────────────────────────────────
    public bool CanCreateEvents { get; init; } = false;
    /// <summary>Events creatable per calendar month. -1 = unlimited.</summary>
    public int MonthlyEventLimit { get; init; } = 0;
    public int? EventAttendeeCap { get; init; } = null;
    public bool CanGenerateQrCheckin { get; init; } = false;
    public bool CanExportAttendees { get; init; } = false;
    public bool CanPinAnnouncements { get; init; } = false;
    public bool EventsPriorityListing { get; init; } = false;

    // ─── Analytics ───────────────────────────────────────────────────────────
    public AnalyticsAccessLevel AnalyticsAccess { get; init; } = AnalyticsAccessLevel.None;
    public bool CanExportAnalyticsPdf { get; init; } = false;

    // ─── Admin & Enterprise ──────────────────────────────────────────────────
    /// <summary>How many co-admins the account can have. -1 = unlimited.</summary>
    public int MaxAccountAdmins { get; init; } = 1;
    public bool CanBroadcastMessages { get; init; } = false;
    public bool HasWebhookAccess { get; init; } = false;
    public bool HasWhiteLabel { get; init; } = false;
    public bool HasSlaSupport { get; init; } = false;
    public bool HasDedicatedManager { get; init; } = false;

    // ─── Leaderboard ─────────────────────────────────────────────────────────
    /// <summary>How many leaderboard entries are visible. -1 = full leaderboard.</summary>
    public int LeaderboardVisibilityCap { get; init; } = 10;

    public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    // Navigation
    public SubscriptionPlan? Plan { get; init; }

    // ─── Helper Methods ───────────────────────────────────────────────────────

    /// <summary>Returns true if the user has unlimited swipes today.</summary>
    public bool HasUnlimitedSwipes => DailySwipeLimit == -1;

    /// <summary>Returns true if the user has unlimited matches.</summary>
    public bool HasUnlimitedMatches => MaxActiveMatches == -1;

    /// <summary>Returns true if the user can create unlimited events.</summary>
    public bool HasUnlimitedEvents => MonthlyEventLimit == -1;

    /// <summary>Returns true if the user has access to any analytics.</summary>
    public bool HasAnyAnalyticsAccess => AnalyticsAccess != AnalyticsAccessLevel.None;

    /// <summary>Returns true if the user has advanced analytics (Community Pro+).</summary>
    public bool HasAdvancedAnalytics => AnalyticsAccess == AnalyticsAccessLevel.Advanced;
}
