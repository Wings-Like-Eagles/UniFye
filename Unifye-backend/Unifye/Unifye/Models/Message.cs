namespace Unifye.Models;

public class Message
{
    public Guid Id { get; set; }

    public Guid SenderId { get; set; }

    public Guid ReceiverId { get; set; }

    public string Content { get; set; } = string.Empty;

    public bool IsRead { get; set; }

    public DateTimeOffset SentAt { get; set; } = DateTimeOffset.UtcNow;

    public User Sender { get; set; } = null!;

    public User Receiver { get; set; } = null!;
}
