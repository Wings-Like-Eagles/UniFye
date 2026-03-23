namespace Unifye.Models;

public class UserSwipe
{
    public int Id { get; set; }

    public Guid SourceUserId { get; set; }

    public Guid TargetUserId { get; set; }

    public bool IsLiked { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
