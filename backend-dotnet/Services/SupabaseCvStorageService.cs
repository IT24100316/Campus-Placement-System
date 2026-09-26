using Microsoft.AspNetCore.Http;
using System.Net.Http.Headers;

namespace backend_dotnet.Services;

public sealed class SupabaseCvStorageService : ICvStorageService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SupabaseCvStorageService> _logger;

    public SupabaseCvStorageService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<SupabaseCvStorageService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<string> StoreAsync(
        Guid studentId,
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        var settings = GetSettings();
        var objectKey = $"{studentId:N}/{Guid.NewGuid():N}.pdf";
        using var request = CreateRequest(HttpMethod.Post, settings, objectKey);
        request.Headers.TryAddWithoutValidation("x-upsert", "false");
        request.Content = new StreamContent(file.OpenReadStream());
        request.Content.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");

        await SendAsync(request, "upload", cancellationToken);
        return objectKey;
    }

    public async Task DeleteAsync(string storageKey, CancellationToken cancellationToken = default)
    {
        if (!IsValidObjectKey(storageKey))
        {
            _logger.LogError("Refusing to delete a CV with an invalid storage key.");
            throw new CvStorageException("Unable to delete the CV at this time.");
        }

        var settings = GetSettings();
        using var request = CreateRequest(HttpMethod.Delete, settings, storageKey);
        await SendAsync(request, "delete", cancellationToken, allowNotFound: true);
    }

    private (string Url, string Key, string Bucket) GetSettings()
    {
        var url = _configuration["Supabase:Url"]?.Trim().TrimEnd('/');
        var key = _configuration["Supabase:ServiceRoleKey"]?.Trim();
        var bucket = _configuration["Supabase:CvBucket"]?.Trim();

        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri)
            || uri.Scheme != Uri.UriSchemeHttps
            || !SupabaseStorageAuthentication.IsPrivilegedKey(key)
            || string.IsNullOrWhiteSpace(bucket)
            || bucket.Contains('/')
            || bucket.Contains('\\'))
        {
            _logger.LogError("Supabase CV storage is not configured correctly.");
            throw new CvStorageException("CV storage is unavailable at this time.");
        }

        return (url!, key!, bucket!);
    }

    private static bool IsValidObjectKey(string key)
    {
        var segments = key?.Split('/');
        return segments is { Length: 2 }
            && Guid.TryParseExact(segments[0], "N", out _)
            && Guid.TryParseExact(Path.GetFileNameWithoutExtension(segments[1]), "N", out _)
            && segments[1].EndsWith(".pdf", StringComparison.OrdinalIgnoreCase);
    }

    private static HttpRequestMessage CreateRequest(
        HttpMethod method,
        (string Url, string Key, string Bucket) settings,
        string objectKey)
    {
        var escapedKey = string.Join('/', objectKey.Split('/').Select(Uri.EscapeDataString));
        var uri = $"{settings.Url}/storage/v1/object/{Uri.EscapeDataString(settings.Bucket)}/{escapedKey}";
        var request = new HttpRequestMessage(method, uri);
        SupabaseStorageAuthentication.AddHeaders(request, settings.Key);
        return request;
    }

    private async Task SendAsync(
        HttpRequestMessage request,
        string operation,
        CancellationToken cancellationToken,
        bool allowNotFound = false)
    {
        try
        {
            using var response = await _httpClient.SendAsync(request, cancellationToken);
            if (response.IsSuccessStatusCode
                || (allowNotFound && response.StatusCode == System.Net.HttpStatusCode.NotFound))
            {
                return;
            }

            _logger.LogError(
                "Supabase CV {Operation} failed with HTTP {StatusCode}.",
                operation,
                (int)response.StatusCode);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (OperationCanceledException)
        {
            _logger.LogError("Supabase CV {Operation} request timed out.", operation);
        }
        catch (HttpRequestException)
        {
            _logger.LogError("Supabase CV {Operation} request failed.", operation);
        }

        throw new CvStorageException($"Unable to {operation} the CV at this time.");
    }
}

public sealed class CvStorageException : Exception
{
    public CvStorageException(string message) : base(message) { }
}
