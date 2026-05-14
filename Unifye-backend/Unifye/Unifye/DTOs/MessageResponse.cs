namespace Unifye.Features.Messages.DTOs;

public class MessageResponse
{
    public Guid Id { get; set; }

    public Guid SenderId { get; set; }

    public Guid ReceiverId { get; set; }

    public string Content { get; set; } = string.Empty;

    public bool IsRead { get; set; }

    public DateTimeOffset SentAt { get; set; }
}
