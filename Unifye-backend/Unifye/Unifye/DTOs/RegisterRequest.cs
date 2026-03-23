using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;

namespace Unifye.DTOs;

public class RegisterRequest
{
    [FromForm(Name = "firstName")]
    [Required]
    [MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [FromForm(Name = "lastName")]
    [Required]
    [MaxLength(100)]
    public string LastName { get; set; } = string.Empty;

    [FromForm(Name = "email")]
    [Required]
    [EmailAddress]
    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;

    [FromForm(Name = "password")]
    [Required]
    [MinLength(8)]
    [MaxLength(100)]
    public string Password { get; set; } = string.Empty;

    [FromForm(Name = "gender")]
    [Required]
    [MaxLength(50)]
    public string Gender { get; set; } = string.Empty;

    [FromForm(Name = "dateOfBirth")]
    [Required]
    public string DateOfBirth { get; set; } = string.Empty;

    [FromForm(Name = "interests")]
    public string? Interests { get; set; }

    [FromForm(Name = "image")]
    public IFormFile? Image { get; set; }
}
