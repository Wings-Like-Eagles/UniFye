namespace Unifye.Models;

public class EventAttendee
{
    public Guid EventId { get; set; }
    public Guid UserId { get; set; }
    public DateTime JoinedAt { get; set; }
    public bool IsOrganiser { get; set; }

    // Navigation
    public Event Event { get; set; } = null!;
    public User User { get; set; } = null!;
}

    