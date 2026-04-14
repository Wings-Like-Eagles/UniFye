using Unifye.DTOs;

namespace Unifye.Services
{
    public interface IUserService
    {
        Task<UserResponse?> GetByIdAsync(Guid id, CancellationToken cancellationToken);

        Task<UserResponse?> UpdateProfileAsync(Guid id, ProfileUpdateRequest request, CancellationToken cancellationToken);

        Task<string?> UpdateProfileImageAsync(Guid id, IFormFile image, CancellationToken cancellationToken);
    }
}
