using Microsoft.EntityFrameworkCore;
using Unifye.Enums;
using Unifye.Models;

namespace Unifye.Data.Seeders;

public static class SubscriptionPlanSeeder
{
    public static async Task SeedAsync(ApplicationDbContext db, ILogger logger)
    {
        // Skip if already seeded
        if (await db.SubscriptionPlans.AnyAsync())
        {
            logger.LogInformation("Subscription plans already seeded — skipping.");
            return;
        }

        logger.LogInformation("Seeding subscription plans...");

        var plans = new List<(SubscriptionPlan Plan, PlanFeaturePermissions Permissions)>
        {
            // ─── Free ─────────────────────────────────────────────────────────────
            (
                new SubscriptionPlan
                {
                    Tier            = SubscriptionTier.Free,
                    DisplayName     = "Free",
                    Description     = "Get started and find your campus community.",
                    BadgeLabel      = null,
                    BadgeColourHex  = null,
                    MonthlyPriceZar = 0,
                    AnnualPriceZar  = null,
                    IsActive        = true,
                    SortOrder       = 1,
                },
                new PlanFeaturePermissions
                {
                    Tier                    = SubscriptionTier.Free,
                    DailySwipeLimit         = 10,
                    MaxActiveMatches        = 3,
                    CanSeeWhoLikedMe        = false,
                    CanSendMedia            = false,
                    CanSendVoiceNotes       = false,
                    HasReadReceipts         = false,
                    WeeklyProfileBoostCount = 0,
                    HasVerifiedOrganiserBadge = false,
                    MaxJoinedCommunities    = 1,
                    CanCreateCommunity      = false,
                    MaxOwnedCommunities     = 0,
                    CommunityMemberCap      = 0,
                    CanCreateEvents         = false,
                    MonthlyEventLimit       = 0,
                    CanGenerateQrCheckin    = false,
                    CanExportAttendees      = false,
                    CanPinAnnouncements     = false,
                    EventsPriorityListing   = false,
                    AnalyticsAccess         = AnalyticsAccessLevel.None,
                    CanExportAnalyticsPdf   = false,
                    MaxAccountAdmins        = 1,
                    CanBroadcastMessages    = false,
                    HasWebhookAccess        = false,
                    HasWhiteLabel           = false,
                    HasSlaSupport           = false,
                    HasDedicatedManager     = false,
                    LeaderboardVisibilityCap = 10,
                }
            ),

            // ─── Plus ─────────────────────────────────────────────────────────────
            (
                new SubscriptionPlan
                {
                    Tier                 = SubscriptionTier.Plus,
                    DisplayName          = "Plus",
                    Description          = "More connections, more features.",
                    BadgeLabel           = "Most Popular",
                    BadgeColourHex       = "#FF5C8D",
                    MonthlyPriceZar      = 99,
                    AnnualPriceZar       = 899,
                    IsActive             = true,
                    SortOrder            = 2,
                },
                new PlanFeaturePermissions
                {
                    Tier                    = SubscriptionTier.Plus,
                    DailySwipeLimit         = 50,
                    MaxActiveMatches        = 20,
                    CanSeeWhoLikedMe        = true,
                    CanSendMedia            = true,
                    CanSendVoiceNotes       = true,
                    HasReadReceipts         = false,
                    WeeklyProfileBoostCount = 1,
                    HasVerifiedOrganiserBadge = false,
                    MaxJoinedCommunities    = 5,
                    CanCreateCommunity      = false,
                    MaxOwnedCommunities     = 0,
                    CommunityMemberCap      = 0,
                    CanCreateEvents         = false,
                    MonthlyEventLimit       = 0,
                    CanGenerateQrCheckin    = false,
                    CanExportAttendees      = false,
                    CanPinAnnouncements     = false,
                    EventsPriorityListing   = false,
                    AnalyticsAccess         = AnalyticsAccessLevel.None,
                    CanExportAnalyticsPdf   = false,
                    MaxAccountAdmins        = 1,
                    CanBroadcastMessages    = false,
                    HasWebhookAccess        = false,
                    HasWhiteLabel           = false,
                    HasSlaSupport           = false,
                    HasDedicatedManager     = false,
                    LeaderboardVisibilityCap = 50,
                }
            ),

            // ─── Community Pro ────────────────────────────────────────────────────
            (
                new SubscriptionPlan
                {
                    Tier                 = SubscriptionTier.CommunityPro,
                    DisplayName          = "Community Pro",
                    Description          = "For organisers and community builders.",
                    BadgeLabel           = "Best Value",
                    BadgeColourHex       = "#7C3AED",
                    MonthlyPriceZar      = 199,
                    AnnualPriceZar       = 1799,
                    IsActive             = true,
                    SortOrder            = 3,
                },
                new PlanFeaturePermissions
                {
                    Tier                    = SubscriptionTier.CommunityPro,
                    DailySwipeLimit         = -1,
                    MaxActiveMatches        = -1,
                    CanSeeWhoLikedMe        = true,
                    CanSendMedia            = true,
                    CanSendVoiceNotes       = true,
                    HasReadReceipts         = true,
                    WeeklyProfileBoostCount = 3,
                    HasVerifiedOrganiserBadge = true,
                    MaxJoinedCommunities    = -1,
                    CanCreateCommunity      = true,
                    MaxOwnedCommunities     = 3,
                    CommunityMemberCap      = 500,
                    CanCreateEvents         = true,
                    MonthlyEventLimit       = 10,
                    CanGenerateQrCheckin    = true,
                    CanExportAttendees      = true,
                    CanPinAnnouncements     = true,
                    EventsPriorityListing   = true,
                    AnalyticsAccess         = AnalyticsAccessLevel.Basic,
                    CanExportAnalyticsPdf   = false,
                    MaxAccountAdmins        = 3,
                    CanBroadcastMessages    = false,
                    HasWebhookAccess        = false,
                    HasWhiteLabel           = false,
                    HasSlaSupport           = false,
                    HasDedicatedManager     = false,
                    LeaderboardVisibilityCap = -1,
                }
            ),

            // ─── Campus Enterprise ────────────────────────────────────────────────
            (
                new SubscriptionPlan
                {
                    Tier                 = SubscriptionTier.CampusEnterprise,
                    DisplayName          = "Campus Enterprise",
                    Description          = "For institutions and large organisations.",
                    BadgeLabel           = "Enterprise",
                    BadgeColourHex       = "#1D4ED8",
                    MonthlyPriceZar      = 999,
                    AnnualPriceZar       = null,
                    IsActive             = true,
                    SortOrder            = 4,
                },
                new PlanFeaturePermissions
                {
                    Tier                    = SubscriptionTier.CampusEnterprise,
                    DailySwipeLimit         = -1,
                    MaxActiveMatches        = -1,
                    CanSeeWhoLikedMe        = true,
                    CanSendMedia            = true,
                    CanSendVoiceNotes       = true,
                    HasReadReceipts         = true,
                    WeeklyProfileBoostCount = -1,
                    HasVerifiedOrganiserBadge = true,
                    MaxJoinedCommunities    = -1,
                    CanCreateCommunity      = true,
                    MaxOwnedCommunities     = -1,
                    CommunityMemberCap      = -1,
                    CanCreateEvents         = true,
                    MonthlyEventLimit       = -1,
                    CanGenerateQrCheckin    = true,
                    CanExportAttendees      = true,
                    CanPinAnnouncements     = true,
                    EventsPriorityListing   = true,
                    AnalyticsAccess         = AnalyticsAccessLevel.Advanced,
                    CanExportAnalyticsPdf   = true,
                    MaxAccountAdmins        = -1,
                    CanBroadcastMessages    = true,
                    HasWebhookAccess        = true,
                    HasWhiteLabel           = true,
                    HasSlaSupport           = true,
                    HasDedicatedManager     = true,
                    LeaderboardVisibilityCap = -1,
                }
            ),
        };

        foreach (var (plan, permissions) in plans)
        {
            plan.Permissions?.GetType(); // satisfy nullable — permissions linked below
            var trackedPlan = new SubscriptionPlan
            {
                Id = plan.Id,
                Tier = plan.Tier,
                DisplayName = plan.DisplayName,
                Description = plan.Description,
                BadgeLabel = plan.BadgeLabel,
                BadgeColourHex = plan.BadgeColourHex,
                MonthlyPriceZar = plan.MonthlyPriceZar,
                AnnualPriceZar = plan.AnnualPriceZar,
                IsActive = plan.IsActive,
                SortOrder = plan.SortOrder,
            };

            db.SubscriptionPlans.Add(trackedPlan);

            db.PlanFeaturePermissions.Add(new PlanFeaturePermissions
            {
                PlanId = trackedPlan.Id,
                Tier = permissions.Tier,
                DailySwipeLimit = permissions.DailySwipeLimit,
                MaxActiveMatches = permissions.MaxActiveMatches,
                CanSeeWhoLikedMe = permissions.CanSeeWhoLikedMe,
                CanSendMedia = permissions.CanSendMedia,
                CanSendVoiceNotes = permissions.CanSendVoiceNotes,
                HasReadReceipts = permissions.HasReadReceipts,
                WeeklyProfileBoostCount = permissions.WeeklyProfileBoostCount,
                HasVerifiedOrganiserBadge = permissions.HasVerifiedOrganiserBadge,
                MaxJoinedCommunities = permissions.MaxJoinedCommunities,
                CanCreateCommunity = permissions.CanCreateCommunity,
                MaxOwnedCommunities = permissions.MaxOwnedCommunities,
                CommunityMemberCap = permissions.CommunityMemberCap,
                CanCreateEvents = permissions.CanCreateEvents,
                MonthlyEventLimit = permissions.MonthlyEventLimit,
                CanGenerateQrCheckin = permissions.CanGenerateQrCheckin,
                CanExportAttendees = permissions.CanExportAttendees,
                CanPinAnnouncements = permissions.CanPinAnnouncements,
                EventsPriorityListing = permissions.EventsPriorityListing,
                AnalyticsAccess = permissions.AnalyticsAccess,
                CanExportAnalyticsPdf = permissions.CanExportAnalyticsPdf,
                MaxAccountAdmins = permissions.MaxAccountAdmins,
                CanBroadcastMessages = permissions.CanBroadcastMessages,
                HasWebhookAccess = permissions.HasWebhookAccess,
                HasWhiteLabel = permissions.HasWhiteLabel,
                HasSlaSupport = permissions.HasSlaSupport,
                HasDedicatedManager = permissions.HasDedicatedManager,
                LeaderboardVisibilityCap = permissions.LeaderboardVisibilityCap,
            });
        }

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded {Count} subscription plans.", plans.Count);
    }
}
