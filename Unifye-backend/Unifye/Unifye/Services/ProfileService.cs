using Microsoft.EntityFrameworkCore;
using Unifye.Data;
using Unifye.DTOs;
using Unifye.Models;

namespace Unifye.Services;

public class ProfileService(
    ApplicationDbContext dbContext,
    IWebHostEnvironment environment,
    ILogger<ProfileService> logger) : IProfileService
{
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;
    private static readonly HashSet<string> AllowedImageTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp"
    };

    public async Task<AuthServiceResult<UserResponse>> GetProfileAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await FindUserAsync(userId, cancellationToken);
        if (user is null)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status404NotFound, "User not found.");
        }

        return AuthServiceResult<UserResponse>.Ok(ToResponse(user));
    }

    // Notes are made in the update Profile.

    public async Task<AuthServiceResult<UserResponse>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken cancellationToken)
    {
        var user = await FindUserAsync(userId, cancellationToken);
        if (user is null)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status404NotFound, "User not found.");
        }

        var profile = user.Profile;

        // This just makes sure that the user does not include white spaces in their request. We can maybe remove this entirely by just creating validations at the front end. 

        if (!string.IsNullOrWhiteSpace(request.FirstName))
        {
            profile.FirstName = request.FirstName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.LastName))
        {
            profile.LastName = request.LastName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.Gender))
        {
            profile.Gender = request.Gender.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.DateOfBirth))
        {
            if (!DateOnly.TryParse(request.DateOfBirth, out var dateOfBirth))
            {
                return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Date of birth must be a valid date.");
            }

            if (dateOfBirth > DateOnly.FromDateTime(DateTime.UtcNow))
            {
                return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Date of birth cannot be in the future.");
            }

            profile.DateOfBirth = dateOfBirth;
        }

        if (request.Interests is not null)
        {
            var updatedInterests = ParseInterests(request.Interests);

            profile.Interests.Clear();
            foreach (var interest in updatedInterests)
            {
                profile.Interests.Add(new UserInterest { Interest = interest });
            }
        }

        // Please check the update function properly. Looking at the if statement if the interest is not null. What happens when the interest is null. Does it keep the other intersest still.

        await dbContext.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Updated profile for user {UserId}", userId);
        return AuthServiceResult<UserResponse>.Ok(ToResponse(user));
    }

    public async Task<AuthServiceResult<UserResponse>> UpdateProfileImageAsync(Guid userId, IFormFile image, CancellationToken cancellationToken)
    {
        var user = await FindUserAsync(userId, cancellationToken);
        if (user is null)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status404NotFound, "User not found.");
        }

        if (image.Length == 0)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Uploaded image is empty.");
        }

        if (image.Length > MaxImageSizeBytes)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Image size exceeds the 5MB limit.");
        }

        if (!AllowedImageTypes.Contains(image.ContentType))
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "Only JPG, PNG, and WEBP images are allowed.");
        }

        // Delete the old image file from disk if one exists
        if (!string.IsNullOrWhiteSpace(user.Profile.ImageUrl))
        {
            DeleteImageFile(user.Profile.ImageUrl);
        }

        user.Profile.ImageUrl = await SaveProfileImageAsync(image, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Updated profile image for user {UserId}", userId);
        return AuthServiceResult<UserResponse>.Ok(ToResponse(user));
    }

    public async Task<AuthServiceResult<UserResponse>> DeleteProfileImageAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await FindUserAsync(userId, cancellationToken);
        if (user is null)
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status404NotFound, "User not found.");
        }

        if (string.IsNullOrWhiteSpace(user.Profile.ImageUrl))
        {
            return AuthServiceResult<UserResponse>.Fail(StatusCodes.Status400BadRequest, "User does not have a profile image.");
        }

        DeleteImageFile(user.Profile.ImageUrl);

        user.Profile.ImageUrl = null;
        await dbContext.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Deleted profile image for user {UserId}", userId);
        return AuthServiceResult<UserResponse>.Ok(ToResponse(user));
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private Task<User?> FindUserAsync(Guid userId, CancellationToken cancellationToken)
    {
        return dbContext.Users
            .Include(user => user.Profile)
            .ThenInclude(profile => profile.Interests)
            .FirstOrDefaultAsync(user => user.Id == userId, cancellationToken);
    }

    private async Task<string> SaveProfileImageAsync(IFormFile image, CancellationToken cancellationToken)
    {
        // Analyse what this is?
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

    private void DeleteImageFile(string imageUrl)
    {
        try
        {
            var webRootPath = environment.WebRootPath;
            if (string.IsNullOrWhiteSpace(webRootPath))
            {
                webRootPath = Path.Combine(environment.ContentRootPath, "wwwroot");
            }

            // imageUrl is a relative URL like /uploads/profiles/abc.jpg
            var relativePath = imageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
            var fullPath = Path.Combine(webRootPath, relativePath);

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
                logger.LogInformation("Deleted profile image file {FilePath}", fullPath);
            }
        }
        catch (Exception ex)
        {
            // Non-fatal — log and continue so the DB update still succeeds
            logger.LogWarning(ex, "Failed to delete profile image file for URL {ImageUrl}", imageUrl);
        }
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