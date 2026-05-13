namespace Unifye.Features.Messages.DTOs;

public class SendMessageRequest
{
    public Guid ReceiverId { get; set; }
    public string Content { get; set; } = string.Empty;
}