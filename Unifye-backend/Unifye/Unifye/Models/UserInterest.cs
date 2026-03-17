using System.ComponentModel.DataAnnotations;

namespace Unifye.Models;

public class UserInterest
{
    public int Id { get; set; }

    public Guid UserId { get; set; }

    public User User { get; set; } = null!;

    [MaxLength(100)]
    public required string Interest { get; set; }
}
