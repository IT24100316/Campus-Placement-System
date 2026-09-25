using backend_dotnet.Models;

namespace backend_dotnet.Services;

public interface IJwtService
{
    string GenerateToken(User user);
}
