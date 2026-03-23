using Microsoft.AspNetCore.Mvc;
using Unifye.DTOs;
using Unifye.Services;

namespace Unifye.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(
    IAuthService authService) : ControllerBase
{
    [HttpPost("login")]
    public async Task<ActionResult<object>> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        var result = await authService.LoginAsync(request, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage });
        }

        var user = result.Data!;
        return Ok(new LoginResponseDto
        {
            Success = true,
            Data = new LoginResponseDataDto
            {
                Token = string.Empty,
                User = new LoginUserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Name = $"{user.FirstName} {user.LastName}".Trim(),
                    ImageUrl = user.ImageUrl,
                    PhotoUrl = user.ImageUrl
                }
            }
        });
    }

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
