using System.ComponentModel.DataAnnotations;

namespace Unifye.DTOs;

public class SwipeRequest
{
    [Required]
    public Guid TargetUserId { get; set; }

    public bool IsLiked { get; set; }
}
