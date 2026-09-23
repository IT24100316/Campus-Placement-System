using Microsoft.AspNetCore.Http;

namespace backend_dotnet.Services;

public interface ICvStorageService
{
    Task<string> StoreAsync(Guid studentId, IFormFile file, CancellationToken cancellationToken = default);
    Task DeleteAsync(string storageKey, CancellationToken cancellationToken = default);
}
