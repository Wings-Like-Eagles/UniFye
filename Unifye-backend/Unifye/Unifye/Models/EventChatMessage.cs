namespace Unifye.Models;

public class EventChatMessage
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public Guid SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAtUtc { get; set; }

    // Navigation
    public Event Event { get; set; } = null!;
    public User Sender { get; set; } = null!;
}
