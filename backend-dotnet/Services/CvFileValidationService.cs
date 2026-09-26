using backend_dotnet.Configuration;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace backend_dotnet.Services;

public sealed class CvFileValidationService : ICvFileValidationService
{
    private const string PdfContentType = "application/pdf";
    private static readonly byte[] PdfSignature = "%PDF-"u8.ToArray();
    private readonly CvStorageOptions _storageOptions;

    public CvFileValidationService(IOptions<CvStorageOptions> storageOptions)
    {
        _storageOptions = storageOptions.Value;
    }

    public async Task<CvFileValidationResult> ValidateAsync(
        IFormFile? file,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            return CvFileValidationResult.Invalid("A non-empty PDF CV is required.");
        }

        if (_storageOptions.MaxFileSizeBytes <= 0)
        {
            return CvFileValidationResult.Invalid("CV upload storage is not configured correctly.");
        }

        if (file.Length > _storageOptions.MaxFileSizeBytes)
        {
            return CvFileValidationResult.Invalid(
                $"The CV must not exceed {FormatFileSize(_storageOptions.MaxFileSizeBytes)}.");
        }

        if (!string.Equals(Path.GetExtension(file.FileName), ".pdf", StringComparison.OrdinalIgnoreCase))
        {
            return CvFileValidationResult.Invalid("Only PDF CV files are accepted.");
        }

        var mediaType = file.ContentType?.Split(';', 2)[0].Trim();
        if (!string.Equals(mediaType, PdfContentType, StringComparison.OrdinalIgnoreCase))
        {
            return CvFileValidationResult.Invalid("The CV must use the application/pdf content type.");
        }

        await using var stream = file.OpenReadStream();
        var header = new byte[PdfSignature.Length];
        var bytesRead = 0;

        while (bytesRead < header.Length)
        {
            var read = await stream.ReadAsync(header.AsMemory(bytesRead), cancellationToken);
            if (read == 0)
            {
                break;
            }

            bytesRead += read;
        }

        return bytesRead == PdfSignature.Length && header.AsSpan().SequenceEqual(PdfSignature)
            ? CvFileValidationResult.Valid()
            : CvFileValidationResult.Invalid("The selected file does not contain valid PDF content.");
    }

    private static string FormatFileSize(long byteCount)
    {
        const long bytesPerMegabyte = 1024 * 1024;
        const long bytesPerKilobyte = 1024;

        if (byteCount % bytesPerMegabyte == 0)
        {
            return $"{byteCount / bytesPerMegabyte} MB";
        }

        if (byteCount % bytesPerKilobyte == 0)
        {
            return $"{byteCount / bytesPerKilobyte} KB";
        }

        return $"{byteCount} bytes";
    }
}
