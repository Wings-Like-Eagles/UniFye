namespace Unifye.DTOs;

public record SwipeCandidateResponse(
    Guid Id,
    string FirstName,
    string LastName,
    string Gender,
    DateOnly DateOfBirth,
    IEnumerable<string> Interests,
    string? ImageUrl
);
