using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Unifye.DTOs;
using Unifye.Models;
using Unifye.Services;

namespace Unifye.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ProfileController(IProfileService profileService) : ControllerBase
    {
        /// <summary>
        /// Retrieves the user's profile data. In order to show the profile data for the user but also to the matching card. 
        /// </summary>
        /// <param name="request"></param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        [HttpGet("profile")]
        public async Task<ActionResult<UserResponse>> GetUserProfile([FromForm] User request, CancellationToken cancellationToken)
        {
            var result = await profileService.GetProfileAsync(request.Id, cancellationToken);

            if (result == null)
            {
                return new NotFoundResult();
            }

            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult<UserResponse>> UpdateProfile([FromForm] UpdateProfileRequest request, CancellationToken cancellationToken)
        {
            //// We just have to check how the id is being retrieved with the 
            //var result = await profileService.UpdateProfileAsync(request.Id, request, cancellationToken);

            return Ok();
        }
    }
}
