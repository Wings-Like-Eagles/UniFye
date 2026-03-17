using Unifye.DTOs;

namespace Unifye.Services;

public interface IAuthService
{
    Task<AuthServiceResult<UserResponse>> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken);

    Task<AuthServiceResult<UserResponse>> GetByIdAsync(Guid id, CancellationToken cancellationToken);
}
