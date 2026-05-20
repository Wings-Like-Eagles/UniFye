using Unifye.DTOs;

namespace Unifye.Services
{
    // Please check the following it seems it is not being used at all. 
    public interface IUserService
    {
        Task<UserResponse?> GetByIdAsync(Guid id, CancellationToken cancellationToken);

        Task<UserResponse?> UpdateProfileAsync(Guid id, UpdateProfileRequest request, CancellationToken cancellationToken);

        Task<string?> UpdateProfileImageAsync(Guid id, IFormFile image, CancellationToken cancellationToken);
    }
}
