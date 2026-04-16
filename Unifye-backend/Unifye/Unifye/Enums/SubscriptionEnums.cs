namespace Unifye.Enums
{

    /// <summary>
    /// The 4 subscription tiers available in UniFye.
    /// Maps 1:1 to the PostgreSQL subscription_tier enum.
    /// </summary>
    public enum SubscriptionTier
    {
        Free = 0,
        Plus = 1,
        CommunityPro = 2,
        CampusEnterprise = 3
    }

    /// <summary>
    /// Mirrors Stripe subscription lifecycle statuses.
    /// </summary>
    public enum SubscriptionStatus
    {
        Active,
        Trialing,
        PastDue,
        Canceled,
        Unpaid,
        Paused
    }

    /// <summary>
    /// Controls depth of analytics features available per plan.
    /// </summary>
    public enum AnalyticsAccessLevel
    {
        None,
        Basic,
        Advanced
    }

}
