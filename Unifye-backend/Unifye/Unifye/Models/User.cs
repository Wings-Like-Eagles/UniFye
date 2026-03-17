using System.ComponentModel.DataAnnotations;

namespace Unifye.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();

    [MaxLength(255)]
    public required string Email { get; set; }

    [MaxLength(255)]
    public required string PasswordHash { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public UserProfile Profile { get; set; } = null!;
}
