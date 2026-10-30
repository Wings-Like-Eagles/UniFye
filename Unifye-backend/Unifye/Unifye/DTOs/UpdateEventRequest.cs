namespace Unifye.DTOs
{
    public class UpdateEventRequest
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public DateTime? StartsAtUtc { get; set; }       
        public DateTime? EndsAtUtc { get; set; }
        public int? MaxAttendees { get; set; }
        public string? LocationName { get; set; }
        public string? LocationAddress { get; set; }
        public double? LocationLatitude { get; set; }
        public double? LocationLongitude { get; set; }
    }
}
