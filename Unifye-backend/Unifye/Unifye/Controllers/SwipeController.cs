using Microsoft.AspNetCore.Mvc;
using Unifye.DTOs;
using Unifye.Services;

namespace Unifye.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SwipeController(ISwipeService swipeService) : ControllerBase
{
    [HttpGet("candidates")]
    public async Task<ActionResult<IReadOnlyCollection<SwipeCandidateResponse>>> GetCandidates(
        [FromQuery] Guid userId,
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        if (take <= 0)
        {
            take = 20;
        }

        take = Math.Min(take, 100);

        var result = await swipeService.GetCandidatesAsync(userId, take, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage });
        }

        return Ok(result.Data);
    }

    [HttpPost("{userId:guid}")]
    public async Task<ActionResult<SwipeResultResponse>> Swipe(
        Guid userId,
        [FromBody] SwipeRequest request,
        CancellationToken cancellationToken)
    {
        var result = await swipeService.SwipeAsync(userId, request, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage });
        }

        return Ok(result.Data);
    }

    [HttpGet("{userId:guid}/matches")]
    public async Task<ActionResult<IReadOnlyCollection<UserResponse>>> GetMatches(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await swipeService.GetMatchesAsync(userId, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage });
        }

        return Ok(result.Data);
    }
}
