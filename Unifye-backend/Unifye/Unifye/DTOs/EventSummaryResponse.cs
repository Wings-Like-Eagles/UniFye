namespace Unifye.DTOs;

public class EventSummaryResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public string? LocationName { get; set; }
    public string? LocationAddress { get; set; }
    public double? LocationLatitude { get; set; }
    public double? LocationLongitude { get; set; }
    public int AttendeeCount { get; set; }
    public int? MaxAttendees { get; set; }
    public Guid OrganiserId { get; set; }
    public string OrganiserName { get; set; } = string.Empty;
    public string? OrganiserImageUrl { get; set; }
    public bool IsAttending { get; set; }
    public DateTime CreatedAt { get; set; }
}
