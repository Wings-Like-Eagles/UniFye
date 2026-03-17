using System.ComponentModel.DataAnnotations;

namespace Unifye.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();

    [MaxLength(100)]
    public required string FirstName { get; set; }

    [MaxLength(100)]
    public required string LastName { get; set; }

    [MaxLength(255)]
    public required string Email { get; set; }

    [MaxLength(255)]
    public required string PasswordHash { get; set; }

    [MaxLength(50)]
    public required string Gender { get; set; }

    public DateOnly DateOfBirth { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public ICollection<UserInterest> Interests { get; set; } = new List<UserInterest>();
}
