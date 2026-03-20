using Microsoft.AspNetCore.Identity;

namespace Unifye.DTOs
{
    public class LoginResponseDto
    {
        public bool Success { get; set; }
        public LoginResponseDataDto Data { get; set; } = null!;
    }

    public class LoginResponseDataDto
    {
        public string Token { get; set; } = string.Empty;
        public LoginUserDto User { get; set; } = null!;
    }

    public class LoginUserDto
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public string? PhotoUrl { get; set; }
    }
}
