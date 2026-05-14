namespace Unifye.Services
{
    public interface IStripeService
    {
        // ─── Customer Management ───────────────────────────────────

        Task<string> CreateCustomerAsync(
            Guid userId,
            CancellationToken ct = default);

        // ─── Checkout ──────────────────────────────────────────────

        Task<string> CreateCheckoutSessionAsync(
            string stripeCustomerId,
            string priceId,
            string successUrl,
            string cancelUrl,
            int trialDays = 0,
            CancellationToken ct = default);

        // ─── Billing Portal ────────────────────────────────────────

        Task<string> CreateBillingPortalSessionAsync(
            string stripeCustomerId,
            string returnUrl,
            CancellationToken ct = default);

        // ─── Webhooks ──────────────────────────────────────────────

        Task<(string EventType, dynamic StripeEvent)> ParseAndValidateWebhookAsync(
            string stripeEventJson,
            string stripeSignature,
            CancellationToken ct = default);
    }
}
