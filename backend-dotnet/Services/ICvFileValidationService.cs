using Microsoft.AspNetCore.Http;

namespace backend_dotnet.Services;

public interface ICvFileValidationService
{
    Task<CvFileValidationResult> ValidateAsync(IFormFile? file, CancellationToken cancellationToken = default);
}

public sealed record CvFileValidationResult(bool IsValid, string? ErrorMessage)
{
    public static CvFileValidationResult Valid() => new(true, null);

    public static CvFileValidationResult Invalid(string errorMessage) => new(false, errorMessage);
}
