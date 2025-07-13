namespace unifye_backend.Services
{
    public interface IAuthService
    {
        string HashPassword(string password);
        bool VerifyPassword(string password);
        void GenerateJWTToken(string token);
        
    }
}
