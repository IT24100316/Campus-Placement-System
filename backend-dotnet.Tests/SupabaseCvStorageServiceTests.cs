using System.Net;
using System.Text;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace backend_dotnet.Tests;

public class SupabaseCvStorageServiceTests
{
    private const string Secret = "sb_secret_test-only-value";
    private static readonly Guid StudentId = Guid.Parse("a6ec31e7-d2ef-4de5-9926-1268cee938f5");

    [Fact]
    public async Task StoreAsync_UploadsPdfToPrivateBucketAndReturnsObjectKey()
    {
        string? requestedPath = null;
        var handler = new FakeHandler(async request =>
        {
            Assert.Equal(HttpMethod.Post, request.Method);
            requestedPath = request.RequestUri!.AbsolutePath;
            Assert.Null(request.Headers.Authorization);
            Assert.Equal(Secret, Assert.Single(request.Headers.GetValues("apikey")));
            Assert.Equal("false", Assert.Single(request.Headers.GetValues("x-upsert")));
            Assert.Equal("application/pdf", request.Content!.Headers.ContentType!.MediaType);
            Assert.Equal("%PDF-test"u8.ToArray(), await request.Content.ReadAsByteArrayAsync());
            return new HttpResponseMessage(HttpStatusCode.OK);
        });
        var service = CreateService(handler);

        var key = await service.StoreAsync(StudentId, PdfFile());

        Assert.Matches($"^{StudentId:N}/[0-9a-f]{{32}}\\.pdf$", key);
        Assert.Equal($"/storage/v1/object/student-cvs/{key}", requestedPath);
        Assert.Equal(1, handler.RequestCount);
    }

    [Fact]
    public async Task DeleteAsync_SendsAuthenticatedDeleteForSamePrivateObject()
    {
        var key = $"{StudentId:N}/{Guid.NewGuid():N}.pdf";
        var handler = new FakeHandler(request =>
        {
            Assert.Equal(HttpMethod.Delete, request.Method);
            Assert.Equal($"/storage/v1/object/student-cvs/{key}", request.RequestUri!.AbsolutePath);
            Assert.Null(request.Headers.Authorization);
            Assert.Equal(Secret, Assert.Single(request.Headers.GetValues("apikey")));
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.NoContent));
        });

        await CreateService(handler).DeleteAsync(key);

        Assert.Equal(1, handler.RequestCount);
    }

    [Fact]
    public async Task DeleteAsync_TreatsMissingObjectAsAlreadyDeleted()
    {
        var handler = new FakeHandler(_ => Task.FromResult(
            new HttpResponseMessage(HttpStatusCode.NotFound)));

        await CreateService(handler).DeleteAsync($"{StudentId:N}/{Guid.NewGuid():N}.pdf");

        Assert.Equal(1, handler.RequestCount);
    }

    [Fact]
    public async Task LegacyServiceRoleJwt_UsesBothHeadersForUploadAndDelete()
    {
        var legacyKey = LegacyJwt("service_role");
        var handler = new FakeHandler(request =>
        {
            Assert.Equal(legacyKey, Assert.Single(request.Headers.GetValues("apikey")));
            Assert.Equal($"Bearer {legacyKey}", request.Headers.Authorization?.ToString());
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK));
        });
        var service = CreateService(handler, key: legacyKey);

        var objectKey = await service.StoreAsync(StudentId, PdfFile());
        await service.DeleteAsync(objectKey);

        Assert.Equal(2, handler.RequestCount);
    }

    [Theory]
    [InlineData("sb_publishable_test-only-value")]
    [InlineData("anon")]
    public async Task UnprivilegedKey_IsRejectedBeforeHttpRequest(string key)
    {
        var handler = new FakeHandler(_ => throw new Exception("HTTP must not be called"));

        var exception = await Assert.ThrowsAsync<CvStorageException>(() =>
            CreateService(handler, key: key).StoreAsync(StudentId, PdfFile()));

        Assert.Equal(0, handler.RequestCount);
        Assert.DoesNotContain(key, exception.ToString());
    }

    [Fact]
    public async Task LegacyAnonJwt_IsRejectedBeforeHttpRequest()
    {
        var handler = new FakeHandler(_ => throw new Exception("HTTP must not be called"));
        var key = LegacyJwt("anon");

        await Assert.ThrowsAsync<CvStorageException>(() =>
            CreateService(handler, key: key).StoreAsync(StudentId, PdfFile()));

        Assert.Equal(0, handler.RequestCount);
    }

    [Theory]
    [InlineData("Supabase:Url")]
    [InlineData("Supabase:ServiceRoleKey")]
    [InlineData("Supabase:CvBucket")]
    public async Task StoreAsync_RejectsMissingConfigurationWithoutRequest(string missingSetting)
    {
        var handler = new FakeHandler(_ => throw new Exception("HTTP must not be called"));
        var exception = await Assert.ThrowsAsync<CvStorageException>(() =>
            CreateService(handler, missingSetting).StoreAsync(StudentId, PdfFile()));

        Assert.Equal(0, handler.RequestCount);
        Assert.DoesNotContain(Secret, exception.ToString());
    }

    [Fact]
    public async Task StoreAsync_HidesSupabaseErrorBodyAndCredentials()
    {
        var handler = new FakeHandler(_ => Task.FromResult(
            new HttpResponseMessage(HttpStatusCode.Forbidden)
            {
                Content = new StringContent($"sensitive response {Secret}")
            }));

        var exception = await Assert.ThrowsAsync<CvStorageException>(() =>
            CreateService(handler).StoreAsync(StudentId, PdfFile()));

        Assert.Contains("Unable to upload", exception.Message);
        Assert.DoesNotContain(Secret, exception.ToString());
        Assert.DoesNotContain("sensitive response", exception.ToString());
    }

    [Fact]
    public async Task DeleteAsync_HidesSupabaseErrorBodyAndCredentials()
    {
        var handler = new FakeHandler(_ => Task.FromResult(
            new HttpResponseMessage(HttpStatusCode.InternalServerError)
            {
                Content = new StringContent($"sensitive response {Secret}")
            }));

        var exception = await Assert.ThrowsAsync<CvStorageException>(() =>
            CreateService(handler).DeleteAsync($"{StudentId:N}/{Guid.NewGuid():N}.pdf"));

        Assert.DoesNotContain(Secret, exception.ToString());
        Assert.DoesNotContain("sensitive response", exception.ToString());
    }

    private static SupabaseCvStorageService CreateService(
        HttpMessageHandler handler,
        string? missingSetting = null,
        string? key = null)
    {
        var settings = new Dictionary<string, string?>
        {
            ["Supabase:Url"] = "https://example.supabase.co",
            ["Supabase:ServiceRoleKey"] = key ?? Secret,
            ["Supabase:CvBucket"] = "student-cvs"
        };
        if (missingSetting != null)
        {
            settings[missingSetting] = null;
        }

        var configuration = new ConfigurationBuilder().AddInMemoryCollection(settings).Build();
        return new SupabaseCvStorageService(
            new HttpClient(handler),
            configuration,
            NullLogger<SupabaseCvStorageService>.Instance);
    }

    private static string LegacyJwt(string role)
    {
        static string Encode(string value) => Convert.ToBase64String(Encoding.UTF8.GetBytes(value))
            .TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $"{Encode("{\"alg\":\"HS256\"}")}.{Encode($"{{\"role\":\"{role}\"}}")}.signature";
    }

    private static IFormFile PdfFile()
    {
        var bytes = "%PDF-test"u8.ToArray();
        return new FormFile(new MemoryStream(bytes), 0, bytes.Length, "file", "resume.pdf")
        {
            Headers = new HeaderDictionary(),
            ContentType = "application/pdf"
        };
    }

    private sealed class FakeHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> respond)
        : HttpMessageHandler
    {
        public int RequestCount { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            RequestCount++;
            return await respond(request);
        }
    }
}
