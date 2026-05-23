// Services/IProfileImageService.cs

namespace Unifye.Services
{
    public interface IProfileImageService
    {
        /// <summary>
        /// Saves an image stream to S3 and returns the public URL.
        /// </summary>
        Task<AuthServiceResult<string>> SaveImageAsync(
            Stream stream,
            string contentType,
            string fileName,
            CancellationToken ct = default);

        /// <summary>
        /// Deletes an image from S3 by its full URL or S3 key.
        /// </summary>
        Task<AuthServiceResult<bool>> DeleteImageAsync(
            string imageUrl,
            CancellationToken ct = default);

        /// <summary>
        /// Generates a pre-signed URL for temporary private access (optional use).
        /// </summary>
        Task<AuthServiceResult<string>> GetPresignedUrlAsync(
            string imageUrl,
            int expiryMinutes = 60,
            CancellationToken ct = default);
    }
}
