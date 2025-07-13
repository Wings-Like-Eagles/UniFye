namespace unifye_backend.DTO
{
    public class ProfileDTO
    {
        public string FirstName { get; set; }
        public Gender Gender { get; set; }
        public string University { get; set; }
        public DateTime DateOfBirth { get; set; }
    }

    public enum Gender
    {
        Male,
        Female,
    }
}
