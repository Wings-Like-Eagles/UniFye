using System.Security.Claims;

namespace Unifye.Extensions;

public static class ClaimsPrincipalExtensions
{
    /// <summary>
    /// Reads the authenticated user's id from JWT claims.
    /// Tokens issued by <see cref="Services.AuthService"/> use the standard "sub" claim
    /// (MapInboundClaims is disabled in JWT bearer setup).
    /// </summary>
    public static Guid? GetUserId(this ClaimsPrincipal user)
    {
        var raw = user.FindFirst("sub")?.Value
                  ?? user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                  ?? user.FindFirst("id")?.Value;

        return Guid.TryParse(raw, out var id) ? id : null;
    }
}
