// =============================================================================
// UniFye.Domain — CampusEnterpriseAccount Entity
// File: Domain/Subscriptions/Entities/CampusEnterpriseAccount.cs
// Maps to PostgreSQL: campus_enterprise_accounts table
// =============================================================================

namespace UniFye.Domain.Subscriptions.Entities;

/// <summary>
/// Extended profile for Campus/Enterprise plan subscribers.
/// Stores institutional metadata, multi-admin config, and webhook settings.
/// </summary>
public class CampusEnterpriseAccount
{
    public Guid Id { get; init; } = Guid.NewGuid();

    public Guid SubscriptionId { get; init; }

    public string InstitutionName { get; set; } = string.Empty;

    /// <summary>e.g. "University", "SRC", "Student Society"</summary>
    public string? InstitutionType { get; set; }

    /// <summary>Badge shown on events e.g. "UCT SRC Official"</summary>
    public string? CampusBadgeLabel { get; set; }

    /// <summary>Custom URL slug e.g. "uct-src" → unifye.co.za/e/uct-src</summary>
    public string? CustomSlug { get; set; }

    public string? ContactEmail { get; set; }

    /// <summary>For institutional invoicing via purchase orders.</summary>
    public string? PurchaseOrderNumber { get; set; }

    public string? BillingContactName { get; set; }

    /// <summary>Array of admin User IDs. Max 10 per Campus plan.</summary>
    public List<Guid> AdminUserIds { get; set; } = new();

    public string? WebhookUrl { get; set; }

    public string? WebhookSecret { get; set; }

    public bool IsWhiteLabelEnabled { get; set; } = false;

    /// <summary>Internal notes visible to account managers only.</summary>
    public string? Notes { get; set; }

    public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    // Navigation
    public UserSubscription? Subscription { get; init; }
}
