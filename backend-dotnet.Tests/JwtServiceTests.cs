using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace backend_dotnet.Tests;

public class JwtServiceTests
{
    private const string SigningKey = "Unit-Test-Jwt-Signing-Key-At-Least-32-Bytes-Long!";

    [Fact]
    public void GenerateToken_ContainsExactUserIdentityClaims()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "john@example.edu",
            Role = UserRole.Student
        };

        var token = new JwtService(CreateConfiguration(60)).GenerateToken(user);
        var principal = Validate(token, validateLifetime: true);

        Assert.Equal(user.Id.ToString(), principal.FindFirstValue(ClaimTypes.NameIdentifier));
        Assert.Equal(user.Email, principal.FindFirstValue(ClaimTypes.Name));
        Assert.Equal(user.Email, principal.FindFirstValue(ClaimTypes.Email));
        Assert.Equal("Student", principal.FindFirstValue(ClaimTypes.Role));
    }

    [Fact]
    public void ValidateToken_RejectsExpiredToken()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "expired@example.edu",
            Role = UserRole.Student
        };
        var token = new JwtService(CreateConfiguration(-1)).GenerateToken(user);

        Assert.Throws<SecurityTokenExpiredException>(() => Validate(token, validateLifetime: true));
    }

    private static IConfiguration CreateConfiguration(int expiryMinutes) =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = SigningKey,
                ["Jwt:Issuer"] = "CampusPlacementAPI",
                ["Jwt:Audience"] = "CampusPlacementClient",
                ["Jwt:ExpiryMinutes"] = expiryMinutes.ToString()
            })
            .Build();

    private static ClaimsPrincipal Validate(string token, bool validateLifetime)
    {
        var parameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = validateLifetime,
            ValidateIssuerSigningKey = true,
            ValidIssuer = "CampusPlacementAPI",
            ValidAudience = "CampusPlacementClient",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SigningKey)),
            ClockSkew = TimeSpan.Zero
        };

        return new JwtSecurityTokenHandler().ValidateToken(token, parameters, out _);
    }
}
