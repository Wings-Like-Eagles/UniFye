using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Options;
using Unifye.Configuration;


namespace Unifye.Services
{
    public class ProfileImageService(
        IAmazonS3 s3Client,
        IOptions<AwsS3Options> s3Options,
        ILogger<ProfileImageService> logger) : IProfileImageService
    {
        private readonly AwsS3Options _s3 = s3Options.Value;

        // ─── Save ────────────────────────────────────────────────────────────

        public async Task<AuthServiceResult<string>> SaveImageAsync(
            Stream stream,
            string contentType,
            string fileName,
            CancellationToken ct = default)
        {
            try
            {
                // Build a unique S3 key so uploads never collide
                var key = $"profile-images/{Guid.NewGuid()}/{SanitizeFileName(fileName)}";

                var request = new PutObjectRequest
                {
                    BucketName = _s3.BucketName,
                    Key = key,
                    InputStream = stream,
                    ContentType = contentType,
                    // Make objects publicly readable via CDN / bucket policy
                    CannedACL = S3CannedACL.PublicRead,
                };

                await s3Client.PutObjectAsync(request, ct);

                var url = BuildPublicUrl(key);
                return AuthServiceResult<string>.Ok(url);
            }
            catch (AmazonS3Exception ex)
            {
                logger.LogError(ex, "S3 error saving profile image {FileName}", fileName);
                return AuthServiceResult<string>.Fail(StatusCodes.Status400BadRequest, "Failed to upload image. Please try again.");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Unexpected error saving profile image {FileName}", fileName);
                return AuthServiceResult<string>.Fail(StatusCodes.Status400BadRequest, "An unexpected error occurred.");
            }
        }

        // ─── Delete ──────────────────────────────────────────────────────────

        public async Task<AuthServiceResult<bool>> DeleteImageAsync(
            string imageUrl,
            CancellationToken ct = default)
        {
            try
            {
                var key = ExtractKeyFromUrl(imageUrl);
                if (string.IsNullOrWhiteSpace(key))
                    return AuthServiceResult<bool>.Fail(StatusCodes.Status400BadRequest, "Invalid image URL.");

                var request = new DeleteObjectRequest
                {
                    BucketName = _s3.BucketName,
                    Key = key,
                };

                await s3Client.DeleteObjectAsync(request, ct);
                return AuthServiceResult<bool>.Ok(true);
            }
            catch (AmazonS3Exception ex)
            {
                logger.LogError(ex, "S3 error deleting image {ImageUrl}", imageUrl);
                return AuthServiceResult<bool>.Fail(StatusCodes.Status400BadRequest, "Failed to delete image.");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Unexpected error deleting image {ImageUrl}", imageUrl);
                return AuthServiceResult<bool>.Fail(StatusCodes.Status400BadRequest, "An unexpected error occurred.");
            }
        }

        // ─── Pre-signed URL ──────────────────────────────────────────────────

        public Task<AuthServiceResult<string>> GetPresignedUrlAsync(
            string imageUrl,
            int expiryMinutes = 60,
            CancellationToken ct = default)
        {
            try
            {
                var key = ExtractKeyFromUrl(imageUrl);
                if (string.IsNullOrWhiteSpace(key))
                    return Task.FromResult(AuthServiceResult<string>.Fail(StatusCodes.Status400BadRequest,"Invalid image URL."));

                var request = new GetPreSignedUrlRequest
                {
                    BucketName = _s3.BucketName,
                    Key = key,
                    Expires = DateTime.UtcNow.AddMinutes(expiryMinutes),
                    Verb = HttpVerb.GET,
                };

                var presignedUrl = s3Client.GetPreSignedURL(request);
                return Task.FromResult(AuthServiceResult<string>.Ok(presignedUrl));
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error generating pre-signed URL for {ImageUrl}", imageUrl);
                return Task.FromResult(AuthServiceResult<string>.Fail(StatusCodes.Status400BadRequest, "Could not generate image URL."));
            }
        }

        // ─── Helpers ─────────────────────────────────────────────────────────

        private string BuildPublicUrl(string key)
            // Uses CloudFront domain if configured, falls back to direct S3 URL
            => string.IsNullOrWhiteSpace(_s3.CloudFrontDomain)
                ? $"https://{_s3.BucketName}.s3.{_s3.Region}.amazonaws.com/{key}"
                : $"https://{_s3.CloudFrontDomain}/{key}";

        private string ExtractKeyFromUrl(string url)
        {
            // Strips the bucket/CDN prefix to get the raw S3 key
            if (Uri.TryCreate(url, UriKind.Absolute, out var uri))
                return uri.AbsolutePath.TrimStart('/');

            return string.Empty;
        }

        private static string SanitizeFileName(string fileName)
        {
            var ext = Path.GetExtension(fileName).ToLowerInvariant();
            // Only allow image extensions; default to .jpg if unrecognised
            var safe = ext is ".jpg" or ".jpeg" or ".png" or ".webp" ? ext : ".jpg";
            return $"{Guid.NewGuid()}{safe}";
        }
    }
}
