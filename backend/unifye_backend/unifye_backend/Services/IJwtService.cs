namespace unifye_backend.Services
{
    public interface IJwtService
    {
        string GetJwtToken(string userId, string userEmail);
        bool ValidateToken(string token);
    }
}
