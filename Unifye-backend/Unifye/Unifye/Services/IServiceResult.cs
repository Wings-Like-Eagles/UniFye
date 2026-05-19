namespace Unifye.Services;

public interface IServiceResult
{
    bool Success { get; }
    int StatusCode { get; }
    string? ErrorMessage { get; }
}