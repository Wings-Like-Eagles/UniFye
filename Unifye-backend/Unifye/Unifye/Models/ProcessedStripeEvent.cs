namespace Unifye.Models
{
    /// <summary>
    /// Idempotency guard — records every Stripe event ID we have successfully processed.
    /// Prevents double-processing duplicate webhook deliveries.
    /// </summary>
    public class ProcessedStripeEvent
    {
        public Guid Id { get; init; } = Guid.NewGuid();
        public string StripeEventId { get; init; } = string.Empty;
        public string EventType { get; init; } = string.Empty;
        public DateTimeOffset ProcessedAt { get; init; } = DateTimeOffset.UtcNow;
    }
}
