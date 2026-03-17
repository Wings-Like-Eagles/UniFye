namespace Unifye.DTOs;

public record UserResponse(
    Guid Id,
    string FirstName,
    string LastName,
    string Email,
    string Gender,
    DateOnly DateOfBirth,
    IEnumerable<string> Interests,
    string? ImageUrl,
    DateTime CreatedAtUtc
);
