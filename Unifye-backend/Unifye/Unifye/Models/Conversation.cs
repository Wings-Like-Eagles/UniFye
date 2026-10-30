namespace Unifye.Models;

public class Conversation
{
    public Guid Id { get; set; }

    public Guid UserOneId { get; set; }

    public Guid UserTwoId { get; set; }
    public User UserOne { get; set; } = null!;
    public User UserTwo { get; set; } = null!;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
