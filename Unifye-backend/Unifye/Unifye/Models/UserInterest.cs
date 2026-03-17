using System.ComponentModel.DataAnnotations;

namespace Unifye.Models;

public class UserInterest
{
    public int Id { get; set; }

    public Guid UserProfileId { get; set; }

    public UserProfile UserProfile { get; set; } = null!;

    [MaxLength(100)]
    public required string Interest { get; set; }
}
