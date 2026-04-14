using Unifye.DTOs;
using Unifye.Models;

namespace Unifye.Services
{
    public interface IProfileService
    {
        Task<AuthServiceResult<UserResponse>> GetProfileAsync(Guid userId, CancellationToken cancellationToken);
        Task<AuthServiceResult<UserResponse>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken cancellationToken);
        Task<AuthServiceResult<UserResponse>> UpdateProfileImageAsync(Guid userId, IFormFile image, CancellationToken cancellationToken);
        Task<AuthServiceResult<UserResponse>> DeleteProfileImageAsync(Guid userId, CancellationToken cancellationToken);
    }
}
