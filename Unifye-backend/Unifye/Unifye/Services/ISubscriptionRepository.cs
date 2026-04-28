using Unifye.Enums;
using Unifye.Models;

namespace Unifye.Services
{
    public interface ISubscriptionRepository
    {
        // ─── Subscription Plans ─────────────────────────────────────

        Task<IReadOnlyList<SubscriptionPlan>> GetAllActivePlansAsync(
            CancellationToken ct = default);

        Task<SubscriptionPlan?> GetPlanByTierAsync(
            SubscriptionTier tier,
            CancellationToken ct = default);

        Task<PlanFeaturePermissions?> GetPermissionsForTierAsync(
            SubscriptionTier tier,
            CancellationToken ct = default);

        Task<SubscriptionTier> GetTierByStripePriceIdAsync(
            string stripePriceId,
            CancellationToken ct = default);

        // ─── User Subscription ─────────────────────────────────────

        Task<UserSubscription?> GetUserSubscriptionAsync(
            Guid userId,
            CancellationToken ct = default);

        Task CreateUserSubscriptionAsync(
            UserSubscription subscription,
            CancellationToken ct = default);

        Task UpdateUserSubscriptionAsync(
            UserSubscription subscription,
            CancellationToken ct = default);

        Task UpdateStripeCustomerIdAsync(
            Guid userId,
            string stripeCustomerId,
            CancellationToken ct = default);

        Task<Guid?> GetUserIdByStripeCustomerIdAsync(
            string stripeCustomerId,
            CancellationToken ct = default);

        // ─── Stripe Event Idempotency ──────────────────────────────

        Task<bool> HasProcessedStripeEventAsync(
            string stripeEventId,
            CancellationToken ct = default);

        // ─── Subscription History ──────────────────────────────────

        Task RecordHistoryAsync(
            SubscriptionHistory history,
            CancellationToken ct = default);
    }
}
