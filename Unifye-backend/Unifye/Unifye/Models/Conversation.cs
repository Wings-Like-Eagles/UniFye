namespace Unifye.Models;

public class Conversation
{
    public Guid Id { get; set; }

    public Guid UserOneId { get; set; }

    public Guid UserTwoId { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
