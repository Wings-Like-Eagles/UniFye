using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Unifye.DTOs;
using Unifye.Services;

namespace Unifye.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ProfileController(IProfileService profileService) : ControllerBase
    {
        // ─── GET api/profile ──────────────────────────────────────────────────
        [HttpGet]
        public async Task<ActionResult<UserResponse>> GetUserProfile(CancellationToken cancellationToken)
        {
            var userId = GetUserId();
            if (userId is null) return Unauthorized();

            var result = await profileService.GetProfileAsync(userId.Value, cancellationToken);

            return result.Success
                ? Ok(result.Data)
                : StatusCode(result.StatusCode, result.ErrorMessage);
        }

        // ─── PUT api/profile ──────────────────────────────────────────────────
        [HttpPut]
        public async Task<ActionResult<UserResponse>> UpdateProfile(
            [FromForm] UpdateProfileRequest request,
            CancellationToken cancellationToken)
        {
            var userId = GetUserId();
            if (userId is null) return Unauthorized();

            var result = await profileService.UpdateProfileAsync(userId.Value, request, cancellationToken);

            return result.Success
                ? Ok(result.Data)
                : StatusCode(result.StatusCode, result.ErrorMessage);
        }

        // ─── PUT api/profile/image ────────────────────────────────────────────
        [HttpPut("image")]
        public async Task<ActionResult<UserResponse>> UpdateProfileImage(
            IFormFile image,
            CancellationToken cancellationToken)
        {
            var userId = GetUserId();
            if (userId is null) return Unauthorized();

            if (image is null || image.Length == 0)
                return BadRequest("No image file was provided.");

            var result = await profileService.UpdateProfileImageAsync(userId.Value, image, cancellationToken);

            return result.Success
                ? Ok(result.Data)
                : StatusCode(result.StatusCode, result.ErrorMessage);
        }

        // ─── DELETE api/profile/image ─────────────────────────────────────────
        [HttpDelete("image")]
        public async Task<ActionResult<UserResponse>> DeleteProfileImage(CancellationToken cancellationToken)
        {
            var userId = GetUserId();
            if (userId is null) return Unauthorized();

            var result = await profileService.DeleteProfileImageAsync(userId.Value, cancellationToken);

            return result.Success
                ? Ok(result.Data)
                : StatusCode(result.StatusCode, result.ErrorMessage);
        }

        // ─── Private helpers ──────────────────────────────────────────────────
        private Guid? GetUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(claim, out var id) ? id : null;
        }
    }
}
