namespace Unifye.DTOs;

public class EventAttendeeResponse
{
    public Guid UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public bool IsOrganiser { get; set; }
    public DateTime JoinedAt { get; set; }
}
