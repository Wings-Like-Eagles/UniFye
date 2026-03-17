using Microsoft.AspNetCore.Mvc;
using Unifye.DTOs;
using Unifye.Services;

namespace Unifye.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(
    IAuthService authService) : ControllerBase
{
    [HttpPost("register")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<UserResponse>> Register([FromForm] RegisterRequest request, CancellationToken cancellationToken)
    {
        var result = await authService.RegisterAsync(request, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage });
        }

        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result.Data);
    }

    [HttpGet("users/{id:guid}")]
    public async Task<ActionResult<UserResponse>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await authService.GetByIdAsync(id, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage });
        }

        return Ok(result.Data);
    }
}
