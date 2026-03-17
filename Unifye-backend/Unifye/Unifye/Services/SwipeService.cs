using Microsoft.EntityFrameworkCore;
using Unifye.Data;
using Unifye.DTOs;
using Unifye.Models;

namespace Unifye.Services;

public class SwipeService(ApplicationDbContext dbContext) : ISwipeService
{
    public async Task<AuthServiceResult<IReadOnlyCollection<SwipeCandidateResponse>>> GetCandidatesAsync(
        Guid userId,
        int take,
        CancellationToken cancellationToken)
    {
        var userExists = await dbContext.Users.AnyAsync(user => user.Id == userId, cancellationToken);
        if (!userExists)
        {
            return AuthServiceResult<IReadOnlyCollection<SwipeCandidateResponse>>.Fail(
                StatusCodes.Status404NotFound,
                "User not found.");
        }

        var excludedUserIds = await dbContext.UserSwipes
            .Where(swipe => swipe.SourceUserId == userId)
            .Select(swipe => swipe.TargetUserId)
            .ToListAsync(cancellationToken);

        var candidates = await dbContext.Users
            .AsNoTracking()
            .Include(user => user.Interests)
            .Where(user => user.Id != userId && !excludedUserIds.Contains(user.Id))
            .OrderByDescending(user => user.CreatedAtUtc)
            .Take(take)
            .ToListAsync(cancellationToken);

        var response = candidates
            .Select(candidate => new SwipeCandidateResponse(
                candidate.Id,
                candidate.FirstName,
                candidate.LastName,
                candidate.Gender,
                candidate.DateOfBirth,
                candidate.Interests.Select(interest => interest.Interest),
                candidate.ImageUrl))
            .ToArray();

        return AuthServiceResult<IReadOnlyCollection<SwipeCandidateResponse>>.Ok(response);
    }

    public async Task<AuthServiceResult<SwipeResultResponse>> SwipeAsync(
        Guid userId,
        SwipeRequest request,
        CancellationToken cancellationToken)
    {
        if (userId == request.TargetUserId)
        {
            return AuthServiceResult<SwipeResultResponse>.Fail(
                StatusCodes.Status400BadRequest,
                "User cannot swipe on themselves.");
        }

        var sourceUserExists = await dbContext.Users.AnyAsync(user => user.Id == userId, cancellationToken);
        var targetUserExists = await dbContext.Users.AnyAsync(user => user.Id == request.TargetUserId, cancellationToken);
        if (!sourceUserExists || !targetUserExists)
        {
            return AuthServiceResult<SwipeResultResponse>.Fail(
                StatusCodes.Status404NotFound,
                "Source or target user not found.");
        }

        var existingSwipe = await dbContext.UserSwipes.FirstOrDefaultAsync(
            swipe => swipe.SourceUserId == userId && swipe.TargetUserId == request.TargetUserId,
            cancellationToken);

        if (existingSwipe is null)
        {
            existingSwipe = new UserSwipe
            {
                SourceUserId = userId,
                TargetUserId = request.TargetUserId,
                IsLiked = request.IsLiked
            };
            dbContext.UserSwipes.Add(existingSwipe);
        }
        else
        {
            existingSwipe.IsLiked = request.IsLiked;
            existingSwipe.CreatedAtUtc = DateTime.UtcNow;
        }

        var isMatch = false;
        if (request.IsLiked)
        {
            var reverseLikeExists = await dbContext.UserSwipes.AnyAsync(
                swipe => swipe.SourceUserId == request.TargetUserId &&
                         swipe.TargetUserId == userId &&
                         swipe.IsLiked,
                cancellationToken);

            if (reverseLikeExists)
            {
                var orderedUsers = OrderUsers(userId, request.TargetUserId);
                var matchExists = await dbContext.UserMatches.AnyAsync(
                    match => match.UserOneId == orderedUsers.UserOne && match.UserTwoId == orderedUsers.UserTwo,
                    cancellationToken);

                if (!matchExists)
                {
                    dbContext.UserMatches.Add(new UserMatch
                    {
                        UserOneId = orderedUsers.UserOne,
                        UserTwoId = orderedUsers.UserTwo
                    });
                }

                isMatch = true;
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        var message = isMatch ? "It's a match!" : "Swipe recorded.";
        return AuthServiceResult<SwipeResultResponse>.Ok(
            new SwipeResultResponse(isMatch, isMatch ? request.TargetUserId : null, message));
    }

    public async Task<AuthServiceResult<IReadOnlyCollection<UserResponse>>> GetMatchesAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var userExists = await dbContext.Users.AnyAsync(user => user.Id == userId, cancellationToken);
        if (!userExists)
        {
            return AuthServiceResult<IReadOnlyCollection<UserResponse>>.Fail(
                StatusCodes.Status404NotFound,
                "User not found.");
        }

        var matchUserIds = await dbContext.UserMatches
            .Where(match => match.UserOneId == userId || match.UserTwoId == userId)
            .Select(match => match.UserOneId == userId ? match.UserTwoId : match.UserOneId)
            .ToListAsync(cancellationToken);

        var users = await dbContext.Users
            .AsNoTracking()
            .Include(user => user.Interests)
            .Where(user => matchUserIds.Contains(user.Id))
            .OrderByDescending(user => user.CreatedAtUtc)
            .ToListAsync(cancellationToken);

        var response = users
            .Select(user => new UserResponse(
                user.Id,
                user.FirstName,
                user.LastName,
                user.Email,
                user.Gender,
                user.DateOfBirth,
                user.Interests.Select(interest => interest.Interest),
                user.ImageUrl,
                user.CreatedAtUtc))
            .ToArray();

        return AuthServiceResult<IReadOnlyCollection<UserResponse>>.Ok(response);
    }

    private static (Guid UserOne, Guid UserTwo) OrderUsers(Guid first, Guid second)
    {
        return string.CompareOrdinal(first.ToString("N"), second.ToString("N")) <= 0
            ? (first, second)
            : (second, first);
    }
}
