using backend_dotnet.Configuration;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace backend_dotnet.Services;

public sealed class LocalCvStorageService : ICvStorageService
{
    private readonly CvStorageOptions _storageOptions;
    private readonly IWebHostEnvironment _environment;

    public LocalCvStorageService(
        IOptions<CvStorageOptions> storageOptions,
        IWebHostEnvironment environment)
    {
        _storageOptions = storageOptions.Value;
        _environment = environment;
    }

    public async Task<string> StoreAsync(
        Guid studentId,
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        var storageRoot = GetStorageRoot();
        var studentDirectory = Path.Combine(storageRoot, studentId.ToString("N"));
        Directory.CreateDirectory(studentDirectory);

        var fileName = $"{Guid.NewGuid():N}.pdf";
        var temporaryPath = Path.Combine(studentDirectory, $"{fileName}.uploading");
        var destinationPath = Path.Combine(studentDirectory, fileName);

        try
        {
            await using var destinationStream = new FileStream(
                temporaryPath,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None,
                bufferSize: 81920,
                useAsync: true);

            await file.CopyToAsync(destinationStream, cancellationToken);
            await destinationStream.FlushAsync(cancellationToken);
            File.Move(temporaryPath, destinationPath);
        }
        catch
        {
            if (File.Exists(temporaryPath))
            {
                File.Delete(temporaryPath);
            }

            throw;
        }

        return Path.Combine(studentId.ToString("N"), fileName).Replace('\\', '/');
    }

    public Task DeleteAsync(string storageKey, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var storageRoot = GetStorageRoot();
        var filePath = Path.GetFullPath(Path.Combine(storageRoot, storageKey));
        if (!IsWithinDirectory(storageRoot, filePath))
        {
            return Task.CompletedTask;
        }

        if (File.Exists(filePath))
        {
            File.Delete(filePath);
        }

        return Task.CompletedTask;
    }

    private string GetStorageRoot()
    {
        if (string.IsNullOrWhiteSpace(_storageOptions.RootPath)
            || !Path.IsPathFullyQualified(_storageOptions.RootPath))
        {
            throw new InvalidOperationException("CV storage root path is not configured.");
        }

        var storageRoot = Path.GetFullPath(_storageOptions.RootPath);
        var contentRoot = Path.GetFullPath(_environment.ContentRootPath);
        if (IsWithinDirectory(contentRoot, storageRoot))
        {
            throw new InvalidOperationException("CV storage root must be outside the application workspace.");
        }

        return storageRoot;
    }

    private static bool IsWithinDirectory(string directoryPath, string candidatePath)
    {
        var relativePath = Path.GetRelativePath(directoryPath, candidatePath);
        return !string.Equals(relativePath, "..", StringComparison.Ordinal)
            && !relativePath.StartsWith($"..{Path.DirectorySeparatorChar}", StringComparison.Ordinal)
            && !Path.IsPathRooted(relativePath);
    }
}
