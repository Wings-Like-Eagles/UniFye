using Microsoft.EntityFrameworkCore;
using System.Runtime.CompilerServices;
using Unifye.Data;
using Unifye.DTOs;
using Unifye.Models;

namespace Unifye.Services;

public class AuthService(
    ApplicationDbContext dbContext,
    IWebHostEnvironment environment,
    ILogger<AuthService> logger) : IAuthService
{
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;
    private static readonly HashSet<string> AllowedImageTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp"
    };

    public async Task<AuthServiceResult<UserResponse>> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await dbContext.Users
            .Include(currentUser => currentUser.Profile)
            .ThenInclude(profile => profile.Interests)
            .FirstOrDefaultAsync(currentUser => currentUser.Email == normalizedEmail, cancellationToken);

        if (user is null)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status401Unauthorized, "Invalid email or password.");
        }

        var isValidPassword = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        if (!isValidPassword)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status401Unauthorized, "Invalid email or password.");
        }

        return AuthServiceResult<UserResponse>.Ok(ToResponse(user));
    }

    public async Task<AuthServiceResult<UserResponse>> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var emailInUse = await dbContext.Users.AnyAsync(user => user.Email == normalizedEmail, cancellationToken);
        if (emailInUse)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status409Conflict, "Email address is already in use.");
        }

        if (!DateOnly.TryParse(request.DateOfBirth, out var dateOfBirth))
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Date of birth must be a valid date.");
        }

        if (dateOfBirth > DateOnly.FromDateTime(DateTime.UtcNow))
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Date of birth cannot be in the future.");
        }

        string? imageUrl = null;
        if (request.Image is not null)
        {
            if (request.Image.Length == 0)
            {
                return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Uploaded image is empty.");
            }

            if (request.Image.Length > MaxImageSizeBytes)
            {
                return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Image size exceeds the 5MB limit.");
            }

            if (!AllowedImageTypes.Contains(request.Image.ContentType))
            {
                return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Only JPG, PNG, and WEBP images are allowed.");
            }

            imageUrl = await SaveProfileImageAsync(request.Image, cancellationToken);
        }

        var user = new User
        {
            Email = normalizedEmail,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Profile = new UserProfile
            {
                FirstName = request.FirstName.Trim(),
                LastName = request.LastName.Trim(),
                Gender = request.Gender.Trim(),
                DateOfBirth = dateOfBirth,
                ImageUrl = imageUrl
            }
        };

        var interests = ParseInterests(request.Interests);
        foreach (var interest in interests)
        {
            user.Profile.Interests.Add(new UserInterest { Interest = interest });
        }

        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);

        return AuthServiceResult<UserResponse>.Created(ToResponse(user));
    }

    public async Task<AuthServiceResult<UserResponse>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var user = await dbContext.Users
            .Include(currentUser => currentUser.Profile)
            .ThenInclude(profile => profile.Interests)
            .FirstOrDefaultAsync(currentUser => currentUser.Id == id, cancellationToken);

        if (user is null)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status404NotFound, "User not found.");
        }

        return AuthServiceResult<UserResponse>.Ok(ToResponse(user));
    }

    private async Task<string> SaveProfileImageAsync(IFormFile image, CancellationToken cancellationToken)
    {
        var webRootPath = environment.WebRootPath;
        if (string.IsNullOrWhiteSpace(webRootPath))
        {
            webRootPath = Path.Combine(environment.ContentRootPath, "wwwroot");
        }

        var uploadsFolderPath = Path.Combine(webRootPath, "uploads", "profiles");
        Directory.CreateDirectory(uploadsFolderPath);

        var extension = Path.GetExtension(image.FileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".jpg";
        }

        var fileName = $"{Guid.NewGuid():N}{extension}";
        var filePath = Path.Combine(uploadsFolderPath, fileName);

        await using var fileStream = new FileStream(filePath, FileMode.Create);
        await image.CopyToAsync(fileStream, cancellationToken);

        logger.LogInformation("Saved profile image {FileName}", fileName);
        return $"/uploads/profiles/{fileName}";
    }

    private static IReadOnlyCollection<string> ParseInterests(string? interests)
    {
        if (string.IsNullOrWhiteSpace(interests))
        {
            return Array.Empty<string>();
        }

        return interests
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(interest => interest.ToLowerInvariant())
            .Distinct()
            .ToArray();
    }

    private static UserResponse ToResponse(User user)
    {
        var profile = user.Profile;
        return new UserResponse(
            user.Id,
            profile.FirstName,
            profile.LastName,
            user.Email,
            profile.Gender,
            profile.DateOfBirth,
            profile.Interests.Select(interest => interest.Interest),
            profile.ImageUrl,
            user.CreatedAtUtc);
    }
}
