using Unifye.DTOs;

namespace Unifye.Services;

public interface ISwipeService
{
    Task<AuthServiceResult<IReadOnlyCollection<SwipeCandidateResponse>>> GetCandidatesAsync(
        Guid userId,
        int take,
        CancellationToken cancellationToken);

    Task<AuthServiceResult<SwipeResultResponse>> SwipeAsync(
        Guid userId,
        SwipeRequest request,
        CancellationToken cancellationToken);

    Task<AuthServiceResult<IReadOnlyCollection<UserResponse>>> GetMatchesAsync(
        Guid userId,
        CancellationToken cancellationToken);
}
