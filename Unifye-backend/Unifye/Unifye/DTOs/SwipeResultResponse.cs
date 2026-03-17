namespace Unifye.DTOs;

public record SwipeResultResponse(
    bool IsMatch,
    Guid? MatchedUserId,
    string Message
);
