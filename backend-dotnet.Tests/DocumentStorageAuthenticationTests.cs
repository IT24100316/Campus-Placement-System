using System.Net;
using System.Text;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace backend_dotnet.Tests;

public class DocumentStorageAuthenticationTests
{
    private const string Secret = "sb_secret_test-only-value";

    [Fact]
    public async Task SecretKey_UsesOnlyApiKeyForBucketCheckUploadAndDownload()
    {
        var requests = new List<string>();
        var handler = new FakeHandler(request =>
        {
            Assert.Equal(Secret, Assert.Single(request.Headers.GetValues("apikey")));
            Assert.Null(request.Headers.Authorization);
            requests.Add($"{request.Method} {request.RequestUri!.AbsolutePath}");
            return Task.FromResult(request.Method == HttpMethod.Get
                && request.RequestUri.AbsolutePath.Contains("/object/")
                ? new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new ByteArrayContent("%PDF-test"u8.ToArray())
                }
                : new HttpResponseMessage(HttpStatusCode.OK));
        });
        var service = CreateService(handler, Secret);

        var stored = await service.UploadAsync(PdfFile(), "student-documents");
        var downloaded = await service.OpenReadAsync(stored.StorageKey);

        Assert.StartsWith("supabase://verification-docs/student-documents/", stored.StorageKey);
        Assert.NotNull(downloaded);
        Assert.Contains(requests, item => item.StartsWith("GET /storage/v1/bucket/verification-docs"));
        Assert.Contains(requests, item => item.StartsWith("POST /storage/v1/object/verification-docs/"));
        Assert.Contains(requests, item => item.StartsWith("GET /storage/v1/object/verification-docs/"));
        Assert.Equal(3, handler.RequestCount);
        downloaded?.Content.Dispose();
    }

    [Fact]
    public async Task LegacyServiceRoleJwt_UsesBothHeadersForBucketCheckCreationUploadAndDownload()
    {
        var key = LegacyJwt("service_role");
        var requests = new List<string>();
        var handler = new FakeHandler(request =>
        {
            Assert.Equal(key, Assert.Single(request.Headers.GetValues("apikey")));
            Assert.Equal($"Bearer {key}", request.Headers.Authorization?.ToString());
            requests.Add($"{request.Method} {request.RequestUri!.AbsolutePath}");
            var status = request.Method == HttpMethod.Get
                && request.RequestUri!.AbsolutePath.Contains("/bucket/")
                ? HttpStatusCode.NotFound : HttpStatusCode.OK;
            return Task.FromResult(new HttpResponseMessage(status)
            {
                Content = new ByteArrayContent("%PDF-test"u8.ToArray())
            });
        });
        var service = CreateService(handler, key);

        var stored = await service.UploadAsync(PdfFile(), "student-documents");
        var downloaded = await service.OpenReadAsync(stored.StorageKey);

        Assert.NotNull(downloaded);
        Assert.Contains("POST /storage/v1/bucket", requests);
        Assert.Equal(4, handler.RequestCount);
        downloaded?.Content.Dispose();
    }

    [Theory]
    [InlineData("sb_publishable_test-only-value")]
    [InlineData("anon")]
    public async Task UnprivilegedKey_IsRejectedBeforeDocumentRequests(string key)
    {
        var handler = new FakeHandler(_ => throw new Exception("HTTP must not be called"));
        var service = CreateService(handler, key);

        var exception = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.UploadAsync(PdfFile(), "student-documents"));

        Assert.Equal(0, handler.RequestCount);
        Assert.DoesNotContain(key, exception.ToString());
    }

    [Fact]
    public async Task LegacyAnonJwt_IsRejectedBeforeDownload()
    {
        var handler = new FakeHandler(_ => throw new Exception("HTTP must not be called"));
        var service = CreateService(handler, LegacyJwt("anon"));

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.OpenReadAsync("supabase://verification-docs/student-documents/file.pdf"));

        Assert.Equal(0, handler.RequestCount);
    }

    [Fact]
    public async Task SupabaseFailure_DoesNotExposeBodyOrKeyInException()
    {
        var handler = new FakeHandler(request => Task.FromResult(
            new HttpResponseMessage(request.RequestUri!.AbsolutePath.Contains("/bucket/")
                ? HttpStatusCode.OK : HttpStatusCode.Forbidden)
            {
                Content = new StringContent($"secret response {Secret}")
            }));

        var exception = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService(handler, Secret).UploadAsync(PdfFile(), "student-documents"));

        Assert.DoesNotContain(Secret, exception.ToString());
        Assert.DoesNotContain("secret response", exception.ToString());
    }

    private static DocumentStorageService CreateService(HttpMessageHandler handler, string key)
    {
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(
            new Dictionary<string, string?>
            {
                ["Supabase:Url"] = "https://example.supabase.co",
                ["Supabase:ServiceRoleKey"] = key,
                ["Supabase:VerificationBucket"] = "verification-docs"
            }).Build();
        return new DocumentStorageService(
            new FakeFactory(new HttpClient(handler)), configuration, null!,
            NullLogger<DocumentStorageService>.Instance);
    }

    private static IFormFile PdfFile()
    {
        var bytes = "%PDF-test"u8.ToArray();
        return new FormFile(new MemoryStream(bytes), 0, bytes.Length, "file", "document.pdf")
        {
            Headers = new HeaderDictionary(), ContentType = "application/pdf"
        };
    }

    private static string LegacyJwt(string role)
    {
        static string Encode(string value) => Convert.ToBase64String(Encoding.UTF8.GetBytes(value))
            .TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $"{Encode("{\"alg\":\"HS256\"}")}.{Encode($"{{\"role\":\"{role}\"}}")}.signature";
    }

    private sealed class FakeFactory(HttpClient client) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => client;
    }

    private sealed class FakeHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> respond)
        : HttpMessageHandler
    {
        public int RequestCount { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken cancellationToken)
        {
            RequestCount++;
            return await respond(request);
        }
    }
}
