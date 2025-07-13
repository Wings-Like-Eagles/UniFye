using unifye_backend.DTO;

namespace unifye_backend.Models
{
    public class Profile
    {
        public int Id { get; set; }
        public string FirtsName { get; set; }
        public Gender Gender { get; set; }
        public string University { get; set; }
        public DateTime DateOfBirth { get; set; }
    }
}
