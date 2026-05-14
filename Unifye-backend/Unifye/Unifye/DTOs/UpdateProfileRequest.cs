using System.ComponentModel.DataAnnotations;

namespace Unifye.DTOs;

public record UpdateProfileRequest
{
    [MaxLength(100)]
    public string? FirstName { get; init; }

    [MaxLength(100)]
    public string? LastName { get; init; }

    [MaxLength(50)]
    public string? Gender { get; init; }

    public string? DateOfBirth { get; init; }

    public string? Interests { get; init; }
}