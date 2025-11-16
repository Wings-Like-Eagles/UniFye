namespace unifye_backend.Services
{
    public class JwtService
    {
        private readonly IJwtService _jwtService;
        public JwtService(IJwtService jwtService)
        {
            this._jwtService = jwtService;
        }

        public string GetJwtToken()
        {

        }
    }
}
