namespace Unifye.Models;

public class Event
{
    public Guid Id { get; set; }
    public Guid OrganiserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartsAtUtc { get; set; }
    public DateTime? EndsAtUtc { get; set; }
    public int? MaxAttendees { get; set; }
    public string? LocationName { get; set; }
    public string? LocationAddress { get; set; }
    public double? LocationLatitude { get; set; }
    public double? LocationLongitude { get; set; }
    public DateTime CreatedAtUtc { get; set; }

    // Navigation
    public User Organiser { get; set; } = null!;
    public List<EventAttendee> Attendees { get; set; } = new();
    public List<EventChatMessage> ChatMessages { get; set; } = new();
}
