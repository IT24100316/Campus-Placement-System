using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace backend_dotnet.Services;

public record StoredDocument(string StorageKey, string FileName, string ContentType);

public interface IDocumentStorageService
{
    Task<StoredDocument> UploadAsync(IFormFile file, string folder, CancellationToken cancellationToken = default);
    Task<(Stream Content, string ContentType, string FileName)?> OpenReadAsync(string storageKey, CancellationToken cancellationToken = default);
}

public sealed class DocumentStorageService : IDocumentStorageService
{
    private static readonly HashSet<string> AllowedTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "application/pdf", "image/png", "image/jpeg"
    };

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<DocumentStorageService> _logger;

    public DocumentStorageService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<DocumentStorageService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _environment = environment;
        _logger = logger;
    }

    public async Task<StoredDocument> UploadAsync(IFormFile file, string folder, CancellationToken cancellationToken = default)
    {
        if (file.Length == 0 || file.Length > 10 * 1024 * 1024)
            throw new InvalidOperationException("Document must be between 1 byte and 10 MB.");
        if (!AllowedTypes.Contains(file.ContentType))
            throw new InvalidOperationException("Only PDF, PNG, and JPEG documents are accepted.");

        var safeExtension = file.ContentType switch
        {
            "application/pdf" => ".pdf",
            "image/png" => ".png",
            _ => ".jpg"
        };
        var storageKey = $"{folder.Trim('/')}/{DateTime.UtcNow:yyyy/MM}/{Guid.NewGuid():N}{safeExtension}";

        var supabaseUrl = _configuration["Supabase:Url"]?.TrimEnd('/');
        var serviceKey = _configuration["Supabase:ServiceRoleKey"];
        var bucket = _configuration["Supabase:VerificationBucket"] ?? "verification-docs";

        if (!string.IsNullOrWhiteSpace(supabaseUrl) && !string.IsNullOrWhiteSpace(serviceKey))
        {
            ValidatePrivilegedKey(serviceKey);
            await UploadToSupabaseAsync(file, storageKey, supabaseUrl, serviceKey, bucket, cancellationToken);
            return new StoredDocument($"supabase://{bucket}/{storageKey}", Path.GetFileName(file.FileName), file.ContentType);
        }

        var root = Path.Combine(_environment.ContentRootPath, "App_Data", "verification-docs");
        var fullPath = Path.GetFullPath(Path.Combine(root, storageKey));
        if (!fullPath.StartsWith(Path.GetFullPath(root), StringComparison.Ordinal))
            throw new InvalidOperationException("Invalid storage path.");

        Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);
        await using var target = File.Create(fullPath);
        await file.CopyToAsync(target, cancellationToken);
        _logger.LogWarning("Supabase is not configured; verification document was stored locally at {StorageKey}.", storageKey);
        return new StoredDocument($"local://{storageKey}", Path.GetFileName(file.FileName), file.ContentType);
    }

    public async Task<(Stream Content, string ContentType, string FileName)?> OpenReadAsync(string storageKey, CancellationToken cancellationToken = default)
    {
        if (storageKey.StartsWith("supabase://", StringComparison.OrdinalIgnoreCase))
        {
            var value = storageKey["supabase://".Length..];
            var separator = value.IndexOf('/');
            if (separator < 1) return null;
            var bucket = value[..separator];
            var objectPath = value[(separator + 1)..];
            var supabaseUrl = _configuration["Supabase:Url"]?.TrimEnd('/');
            var serviceKey = _configuration["Supabase:ServiceRoleKey"];
            if (string.IsNullOrWhiteSpace(supabaseUrl) || string.IsNullOrWhiteSpace(serviceKey)) return null;
            ValidatePrivilegedKey(serviceKey);

            var client = _httpClientFactory.CreateClient();
            using var request = new HttpRequestMessage(HttpMethod.Get,
                $"{supabaseUrl}/storage/v1/object/{Uri.EscapeDataString(bucket)}/{EscapePath(objectPath)}");
            AddSupabaseHeaders(request, serviceKey);
            try
            {
                using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
                if (!response.IsSuccessStatusCode) return null;
                var bytes = await response.Content.ReadAsByteArrayAsync(cancellationToken);
                return (new MemoryStream(bytes), response.Content.Headers.ContentType?.MediaType ?? GetContentType(objectPath), Path.GetFileName(objectPath));
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception exception) when (exception is HttpRequestException or OperationCanceledException)
            {
                _logger.LogError("Supabase document download request failed.");
                return null;
            }
        }

        if (!storageKey.StartsWith("local://", StringComparison.OrdinalIgnoreCase)) return null;
        var relativePath = storageKey["local://".Length..];
        var root = Path.GetFullPath(Path.Combine(_environment.ContentRootPath, "App_Data", "verification-docs"));
        var fullPath = Path.GetFullPath(Path.Combine(root, relativePath));
        if (!fullPath.StartsWith(root, StringComparison.Ordinal) || !File.Exists(fullPath)) return null;
        return (File.OpenRead(fullPath), GetContentType(fullPath), Path.GetFileName(fullPath));
    }

    private async Task UploadToSupabaseAsync(IFormFile file, string storageKey, string supabaseUrl, string serviceKey, string bucket, CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient();
        try
        {
            await EnsureBucketExistsAsync(client, supabaseUrl, serviceKey, bucket, cancellationToken);

            using var request = new HttpRequestMessage(HttpMethod.Post,
                $"{supabaseUrl}/storage/v1/object/{Uri.EscapeDataString(bucket)}/{EscapePath(storageKey)}");
            AddSupabaseHeaders(request, serviceKey);
            request.Headers.TryAddWithoutValidation("x-upsert", "false");
            await using var stream = file.OpenReadStream();
            request.Content = new StreamContent(stream);
            request.Content.Headers.ContentType = MediaTypeHeaderValue.Parse(file.ContentType);
            using var response = await client.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Supabase document upload failed with HTTP {StatusCode}.", (int)response.StatusCode);
                throw new InvalidOperationException("Unable to upload the document to Supabase storage.");
            }
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception exception) when (exception is HttpRequestException or OperationCanceledException)
        {
            _logger.LogError("Supabase document upload request failed.");
            throw new InvalidOperationException("Unable to upload the document to Supabase storage.");
        }
    }

    private async Task EnsureBucketExistsAsync(HttpClient client, string url, string key, string bucket, CancellationToken cancellationToken)
    {
        using var check = new HttpRequestMessage(HttpMethod.Get, $"{url}/storage/v1/bucket/{Uri.EscapeDataString(bucket)}");
        AddSupabaseHeaders(check, key);
        using var checkResponse = await client.SendAsync(check, cancellationToken);
        if (checkResponse.IsSuccessStatusCode) return;

        using var create = new HttpRequestMessage(HttpMethod.Post, $"{url}/storage/v1/bucket");
        AddSupabaseHeaders(create, key);
        create.Content = new StringContent(JsonSerializer.Serialize(new { id = bucket, name = bucket, @public = false }), Encoding.UTF8, "application/json");
        using var createResponse = await client.SendAsync(create, cancellationToken);
        if (!createResponse.IsSuccessStatusCode && createResponse.StatusCode != System.Net.HttpStatusCode.Conflict)
        {
            _logger.LogError("Supabase document bucket creation failed with HTTP {StatusCode}.", (int)createResponse.StatusCode);
            throw new InvalidOperationException("Unable to prepare Supabase document storage.");
        }
    }

    private static void AddSupabaseHeaders(HttpRequestMessage request, string key)
    {
        SupabaseStorageAuthentication.AddHeaders(request, key);
    }

    private void ValidatePrivilegedKey(string key)
    {
        if (SupabaseStorageAuthentication.IsPrivilegedKey(key)) return;
        _logger.LogError("Supabase document storage requires a privileged secret key.");
        throw new InvalidOperationException("Document storage is unavailable at this time.");
    }

    private static string EscapePath(string path) => string.Join('/', path.Split('/').Select(Uri.EscapeDataString));
    private static string GetContentType(string path) => Path.GetExtension(path).ToLowerInvariant() switch
    {
        ".pdf" => "application/pdf",
        ".png" => "image/png",
        _ => "image/jpeg"
    };
}
