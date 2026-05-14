using Microsoft.EntityFrameworkCore;
using Unifye.Data;
using Unifye.Enums;
using Unifye.Models;

namespace Unifye.Services;

public class SubscriptionRepository : ISubscriptionRepository
{
    private readonly ApplicationDbContext _db;

    public SubscriptionRepository(ApplicationDbContext db)
    {
        _db = db;
    }

    // ─── Subscription Plans ───────────────────────────────────────────────────

    public async Task<IReadOnlyList<SubscriptionPlan>> GetAllActivePlansAsync(
        CancellationToken ct = default)
    {
        return await _db.SubscriptionPlans
            .Include(p => p.Permissions)
            .Where(p => p.IsActive)
            .OrderBy(p => p.SortOrder)
            .ToListAsync(ct);
    }

    public async Task<SubscriptionPlan?> GetPlanByTierAsync(
        SubscriptionTier tier,
        CancellationToken ct = default)
    {
        return await _db.SubscriptionPlans
            .Include(p => p.Permissions)
            .FirstOrDefaultAsync(p => p.Tier == tier, ct);
    }

    public async Task<PlanFeaturePermissions?> GetPermissionsForTierAsync(
        SubscriptionTier tier,
        CancellationToken ct = default)
    {
        return await _db.PlanFeaturePermissions
            .Include(p => p.Plan)
            .FirstOrDefaultAsync(p => p.Tier == tier, ct);
    }

    public async Task<SubscriptionTier> GetTierByStripePriceIdAsync(
        string stripePriceId,
        CancellationToken ct = default)
    {
        var plan = await _db.SubscriptionPlans
            .FirstOrDefaultAsync(
                p => p.StripeMonthlyPriceId == stripePriceId ||  // ← corrected
                     p.StripeAnnualPriceId == stripePriceId,      // ← corrected
                ct);

        if (plan is null)
            throw new InvalidOperationException(
                $"No plan found for Stripe price ID: {stripePriceId}");

        return plan.Tier;
    }

    // ─── User Subscription ────────────────────────────────────────────────────

    public async Task<UserSubscription?> GetUserSubscriptionAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        return await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.UserId == userId, ct);
    }

    public async Task CreateUserSubscriptionAsync(
        UserSubscription subscription,
        CancellationToken ct = default)
    {
        _db.UserSubscriptions.Add(subscription);
        await _db.SaveChangesAsync(ct);
    }

    public async Task UpdateUserSubscriptionAsync(
        UserSubscription subscription,
        CancellationToken ct = default)
    {
        _db.UserSubscriptions.Update(subscription);
        await _db.SaveChangesAsync(ct);
    }

    public async Task UpdateStripeCustomerIdAsync(
        Guid userId,
        string stripeCustomerId,
        CancellationToken ct = default)
    {
        var subscription = await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.UserId == userId, ct)
            ?? throw new InvalidOperationException(
                $"No subscription found for user {userId}");

        subscription.StripeCustomerId = stripeCustomerId;
        await _db.SaveChangesAsync(ct);
    }

    public async Task<Guid?> GetUserIdByStripeCustomerIdAsync(
        string stripeCustomerId,
        CancellationToken ct = default)
    {
        var subscription = await _db.UserSubscriptions
            .FirstOrDefaultAsync(s => s.StripeCustomerId == stripeCustomerId, ct);

        return subscription?.UserId;
    }

    // ─── Stripe Event Idempotency ─────────────────────────────────────────────

    public async Task<bool> HasProcessedStripeEventAsync(
        string stripeEventId,
        CancellationToken ct = default)
    {
        return await _db.ProcessedStripeEvents
            .AnyAsync(e => e.StripeEventId == stripeEventId, ct);
    }

    // ─── Subscription History ─────────────────────────────────────────────────

    public async Task RecordHistoryAsync(
        SubscriptionHistory history,
        CancellationToken ct = default)
    {
        _db.SubscriptionHistories.Add(history);
        await _db.SaveChangesAsync(ct);
    }
}
