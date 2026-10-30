using Stripe;

namespace Unifye.Services;

public interface IStripeService
{
    Task<string> CreateCustomerAsync(
        Guid userId,
        CancellationToken ct = default);

    Task<string> CreateCheckoutSessionAsync(
        string stripeCustomerId,
        string priceId,
        string successUrl,
        string cancelUrl,
        int trialDays = 0,
        CancellationToken ct = default);

    Task<string> CreateBillingPortalSessionAsync(
        string stripeCustomerId,
        string returnUrl,
        CancellationToken ct = default);

    Task<(string EventType, Stripe.Event StripeEvent)> ParseAndValidateWebhookAsync(
        string stripeEventJson,
        string stripeSignature,
        CancellationToken ct = default);
}
