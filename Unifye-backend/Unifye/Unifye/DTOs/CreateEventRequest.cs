namespace Unifye.DTOs
{
    public class CreateEventRequest
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartsAtUtc { get; set; }        
        public DateTime? EndsAtUtc { get; set; }          
        public int? MaxAttendees { get; set; }
        public string? LocationName { get; set; }
        public string? LocationAddress { get; set; }
        public double? LocationLatitude { get; set; }
        public double? LocationLongitude { get; set; }
    }
}
