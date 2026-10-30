using Microsoft.EntityFrameworkCore;
using Stripe;
using Stripe.Checkout;
using Unifye.Data;

namespace Unifye.Services;

internal sealed class StripeService : IStripeService
{
    private readonly ApplicationDbContext _db;
    private readonly CustomerService _customerService;
    private readonly Stripe.Checkout.SessionService _checkoutSessionService;
    private readonly Stripe.BillingPortal.SessionService _portalSessionService; 
    private readonly string _webhookSecret;

    public StripeService(ApplicationDbContext db, IConfiguration configuration)
    {
        _db = db;

        var apiKey = configuration["Stripe:SecretKey"]
            ?? throw new InvalidOperationException("Stripe:SecretKey is not configured.");

        _webhookSecret = configuration["Stripe:WebhookSecret"]
            ?? throw new InvalidOperationException("Stripe:WebhookSecret is not configured.");

        StripeConfiguration.ApiKey = apiKey;

        _customerService = new CustomerService();
        _checkoutSessionService = new Stripe.Checkout.SessionService();
        _portalSessionService = new Stripe.BillingPortal.SessionService(); // no "Portal" prefix
    }

    // ─── Customer Management ───────────────────────────────────────────────────

    public async Task<string> CreateCustomerAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var user = await _db.Users
            .Include(u => u.Profile)
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new InvalidOperationException($"User {userId} not found.");

        var fullName = user.Profile is null
            ? null
            : $"{user.Profile.FirstName} {user.Profile.LastName}".Trim();

        var options = new CustomerCreateOptions
        {
            Email = user.Email,
            Name = fullName,
            Metadata = new Dictionary<string, string>
            {
                ["userId"] = userId.ToString()
            }
        };

        var customer = await _customerService.CreateAsync(options, cancellationToken: ct);
        return customer.Id;
    }

    // ─── Checkout ─────────────────────────────────────────────────────────────

    public async Task<string> CreateCheckoutSessionAsync(
        string stripeCustomerId,
        string priceId,
        string successUrl,
        string cancelUrl,
        int trialDays = 0,
        CancellationToken ct = default)
    {
        var options = new Stripe.Checkout.SessionCreateOptions
        {
            Customer = stripeCustomerId,
            Mode = "subscription",
            PaymentMethodTypes = ["card"],
            LineItems =
            [
                new Stripe.Checkout.SessionLineItemOptions
                {
                    Price    = priceId,
                    Quantity = 1,
                }
            ],
            SuccessUrl = successUrl,
            CancelUrl = cancelUrl,
            AllowPromotionCodes = true,
        };

        if (trialDays > 0)
        {
            options.SubscriptionData = new SessionSubscriptionDataOptions
            {
                TrialPeriodDays = trialDays,
                TrialSettings = new SessionSubscriptionDataTrialSettingsOptions
                {
                    EndBehavior = new SessionSubscriptionDataTrialSettingsEndBehaviorOptions
                    {
                        MissingPaymentMethod = "cancel"
                    }
                },
            };
        }

        var session = await _checkoutSessionService.CreateAsync(options, cancellationToken: ct);

        return session.Url
            ?? throw new InvalidOperationException(
                $"Stripe did not return a checkout URL for customer {stripeCustomerId}.");
    }

    // ─── Billing Portal ───────────────────────────────────────────────────────

    public async Task<string> CreateBillingPortalSessionAsync(
        string stripeCustomerId,
        string returnUrl,
        CancellationToken ct = default)
    {
        var options = new Stripe.BillingPortal.SessionCreateOptions // no "Portal" prefix
        {
            Customer = stripeCustomerId,
            ReturnUrl = returnUrl,
        };

        var session = await _portalSessionService.CreateAsync(options, cancellationToken: ct);

        return session.Url
            ?? throw new InvalidOperationException(
                $"Stripe did not return a portal URL for customer {stripeCustomerId}.");
    }

    // ─── Webhooks ─────────────────────────────────────────────────────────────

    public Task<(string EventType, Stripe.Event StripeEvent)> ParseAndValidateWebhookAsync(
        string stripeEventJson,
        string stripeSignature,
        CancellationToken ct = default)
    {
        try
        {
            var stripeEvent = EventUtility.ConstructEvent(
                stripeEventJson,
                stripeSignature,
                _webhookSecret,
                throwOnApiVersionMismatch: false);

            return Task.FromResult((stripeEvent.Type, stripeEvent));
        }
        catch (StripeException ex)
        {
            throw new InvalidOperationException(
                $"Webhook validation failed: {ex.Message}", ex);
        }
    }
}
