using System.ComponentModel.DataAnnotations;

namespace Unifye.Models;

public class UserProfile
{
    [Key]
    public Guid UserId { get; set; }

    public User User { get; set; } = null!;

    [MaxLength(100)]
    public required string FirstName { get; set; }

    [MaxLength(100)]
    public required string LastName { get; set; }

    [MaxLength(50)]
    public required string Gender { get; set; }

    public DateOnly DateOfBirth { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    public ICollection<UserInterest> Interests { get; set; } = new List<UserInterest>();
}
