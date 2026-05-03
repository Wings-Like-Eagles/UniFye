using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Stripe;
using Stripe.Checkout;
using Unifye.Data;
using PortalSessionService = Stripe.BillingPortal.SessionService;
using PortalSessionCreateOptions = Stripe.BillingPortal.SessionCreateOptions;

namespace Unifye.Services;

internal class StripeService : IStripeService
{
    private readonly ApplicationDbContext _db;
    private readonly CustomerService _customerService;
    private readonly SessionService _sessionService;
    private readonly PortalSessionService _portalSessionService;
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
        _sessionService = new SessionService();
        _portalSessionService = new PortalSessionService();
    }

    // ─── Customer Management ───────────────────────────────────────────────────

    public async Task<string> CreateCustomerAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var user = await _db.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new InvalidOperationException($"User {userId} not found.");

        var options = new CustomerCreateOptions
        {
            Email = user.Email,
            Name = user.Profile?.FirstName, // ← update to your actual UserProfile name property
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
        var subscriptionData = new SessionSubscriptionDataOptions();

        if (trialDays > 0)
        {
            subscriptionData.TrialSettings = new SessionSubscriptionDataTrialSettingsOptions
            {
                EndBehavior = new SessionSubscriptionDataTrialSettingsEndBehaviorOptions
                {
                    MissingPaymentMethod = "cancel"
                }
            };
            subscriptionData.TrialPeriodDays = trialDays;
        }

        var options = new SessionCreateOptions
        {
            Customer = stripeCustomerId,
            Mode = "subscription",
            PaymentMethodTypes = ["card"],
            LineItems =
            [
                new SessionLineItemOptions
                {
                    Price    = priceId,
                    Quantity = 1
                }
            ],
            SubscriptionData = subscriptionData,
            SuccessUrl = successUrl,
            CancelUrl = cancelUrl,
            AllowPromotionCodes = true,
        };

        var session = await _sessionService.CreateAsync(options, cancellationToken: ct);

        return session.Url;
    }

    // ─── Billing Portal ───────────────────────────────────────────────────────

    public async Task<string> CreateBillingPortalSessionAsync(
        string stripeCustomerId,
        string returnUrl,
        CancellationToken ct = default)
    {
        var options = new PortalSessionCreateOptions
        {
            Customer = stripeCustomerId,
            ReturnUrl = returnUrl
        };

        var session = await _portalSessionService.CreateAsync(options, cancellationToken: ct);

        return session.Url;
    }

    // ─── Webhooks ─────────────────────────────────────────────────────────────

    public Task<(string EventType, dynamic StripeEvent)> ParseAndValidateWebhookAsync(
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

            return Task.FromResult<(string, dynamic)>((stripeEvent.Type, stripeEvent));
        }
        catch (StripeException ex)
        {
            throw new InvalidOperationException(
                $"Webhook validation failed: {ex.Message}", ex);
        }
    }
}
