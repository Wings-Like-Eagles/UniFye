namespace Unifye.Services;

public class AuthServiceResult<T>
{
    public bool Success { get; init; }

    public T? Data { get; init; }

    public int StatusCode { get; init; }

    public string? ErrorMessage { get; init; }

    public static AuthServiceResult<T> Ok(T data) =>
        new() { Success = true, Data = data, StatusCode = StatusCodes.Status200OK };

    public static AuthServiceResult<T> Created(T data) =>
        new() { Success = true, Data = data, StatusCode = StatusCodes.Status201Created };

    public static AuthServiceResult<T> Fail(int statusCode, string errorMessage) =>
        new() { Success = false, StatusCode = statusCode, ErrorMessage = errorMessage };
}
