using Unifye.Enums;

namespace Unifye.Models
{
    /// <summary>
    /// Master plan definition entity.
    /// Seeded at deployment. One row per subscription tier.
    /// </summary>
    public class SubscriptionPlan
    {
        public Guid Id { get; init; } = Guid.NewGuid();

        public SubscriptionTier Tier { get; init; }

        public string DisplayName { get; init; } = string.Empty;

        public string? Description { get; init; }

        /// <summary>UI badge text e.g. "Most Popular", "Best Value"</summary>
        public string? BadgeLabel { get; init; }

        /// <summary>Hex colour for the badge e.g. "#FF4B6E"</summary>
        public string? BadgeColourHex { get; init; }

        public decimal MonthlyPriceZar { get; init; }

        /// <summary>NULL if no annual billing option for this tier.</summary>
        public decimal? AnnualPriceZar { get; init; }

        // Stripe identifiers
        public string? StripeProductId { get; init; }
        public string? StripeMonthlyPriceId { get; init; }
        public string? StripeAnnualPriceId { get; init; }

        public bool IsActive { get; init; } = true;

        public int SortOrder { get; init; }

        public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
        public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

        // Navigation
        public PlanFeaturePermissions? Permissions { get; init; }
    }

}
