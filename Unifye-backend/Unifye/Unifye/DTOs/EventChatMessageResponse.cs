namespace Unifye.DTOs;

public class EventChatMessageResponse       
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public Guid SenderId { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string? SenderImageUrl { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }          
}