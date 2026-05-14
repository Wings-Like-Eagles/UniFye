using Unifye.Enums;

namespace Unifye.Models
{
    /// <summary>
    /// Immutable audit log entry for each subscription state change.
    /// Used for billing disputes, churn analytics, and Stripe event idempotency.
    /// </summary>
    public class SubscriptionHistory
    {
        public Guid Id { get; init; } = Guid.NewGuid();

        public Guid UserId { get; init; }

        public Guid SubscriptionId { get; init; }

        public SubscriptionTier? PreviousTier { get; init; }
        public SubscriptionTier NewTier { get; init; }

        public SubscriptionStatus? PreviousStatus { get; init; }
        public SubscriptionStatus NewStatus { get; init; }

        /// <summary>
        /// Human-readable reason for the change.
        /// e.g. "stripe_webhook", "admin_override", "trial_ended", "payment_failed"
        /// </summary>
        public string? ChangeReason { get; init; }

        /// <summary>
        /// Stripe Event ID used as idempotency key.
        /// Prevents double-processing duplicate webhook deliveries.
        /// </summary>
        public string? StripeEventId { get; init; }

        /// <summary>Any additional data from the Stripe event stored as JSON.</summary>
        public Dictionary<string, object>? Metadata { get; init; }

        public DateTimeOffset ChangedAt { get; init; } = DateTimeOffset.UtcNow;

        // Navigation
        public UserSubscription? Subscription { get; init; }
    }
}
