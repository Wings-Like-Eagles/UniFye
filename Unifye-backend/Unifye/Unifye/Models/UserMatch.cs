namespace Unifye.Models;

public class UserMatch
{
    public int Id { get; set; }

    public Guid UserOneId { get; set; }

    public Guid UserTwoId { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
