using Unifye.Enums;

namespace Unifye.Models
{
    /// <summary>
    /// The live subscription record for a user.
    /// Mirrors the Stripe subscription object and is updated via webhooks.
    /// </summary>
    public class UserSubscription
    {
        public Guid Id { get; init; } = Guid.NewGuid();

        public Guid UserId { get; init; }

        public Guid PlanId { get; set; }

        public SubscriptionTier Tier { get; set; } = SubscriptionTier.Free;

        public SubscriptionStatus Status { get; set; } = SubscriptionStatus.Active;

        // ─── Stripe Integration ───────────────────────────────────────────────────
        /// <summary>Stripe Customer ID e.g. "cus_XXXXX"</summary>
        public string? StripeCustomerId { get; set; }

        /// <summary>Stripe Subscription ID e.g. "sub_XXXXX". NULL for Free tier.</summary>
        public string? StripeSubscriptionId { get; set; }

        /// <summary>Active Stripe Price ID for the current billing interval.</summary>
        public string? StripePriceId { get; set; }

        public bool IsAnnualBilling { get; set; } = false;

        // ─── Billing Period ───────────────────────────────────────────────────────
        public DateTimeOffset? CurrentPeriodStart { get; set; }
        public DateTimeOffset? CurrentPeriodEnd { get; set; }
        public DateTimeOffset? TrialStart { get; set; }
        public DateTimeOffset? TrialEnd { get; set; }
        public DateTimeOffset? CanceledAt { get; set; }

        /// <summary>
        /// True if the user has requested cancellation but it takes effect at period end.
        /// </summary>
        public bool CancelAtPeriodEnd { get; set; } = false;

        /// <summary>
        /// If payment fails, user retains access until this time before forced downgrade.
        /// </summary>
        public DateTimeOffset? GracePeriodEnd { get; set; }

        public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
        public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

        // Navigation
        public SubscriptionPlan? Plan { get; set; }

        // ─── Computed Properties ──────────────────────────────────────────────────

        /// <summary>Returns true if the subscription is currently in a usable state.</summary>
        public bool IsAccessible =>
            Status is SubscriptionStatus.Active or SubscriptionStatus.Trialing ||
            (Status == SubscriptionStatus.PastDue && GracePeriodEnd > DateTimeOffset.UtcNow);

        /// <summary>Returns true if the user is on the free tier.</summary>
        public bool IsFree => Tier == SubscriptionTier.Free;

        /// <summary>Returns true if the subscription has an upcoming cancellation.</summary>
        public bool IsPendingCancellation => CancelAtPeriodEnd && CurrentPeriodEnd.HasValue;

        /// <summary>Returns true if currently in a Stripe trial period.</summary>
        public bool IsTrialing => Status == SubscriptionStatus.Trialing &&
                                  TrialEnd.HasValue &&
                                  TrialEnd.Value > DateTimeOffset.UtcNow;

        /// <summary>Days remaining in the current billing period.</summary>
        public int? DaysRemainingInPeriod =>
            CurrentPeriodEnd.HasValue
                ? Math.Max(0, (int)(CurrentPeriodEnd.Value - DateTimeOffset.UtcNow).TotalDays)
                : null;
    }
}
