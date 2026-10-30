namespace Unifye.Configuration
{
    public class AwsS3Options
    {
        public const string Section = "AWS:S3";
        public string BucketName { get; init; } = string.Empty;
        public string Region { get; init; } = "af-south-1";
        public string CloudFrontDomain { get; init; } = string.Empty;
    }
}
