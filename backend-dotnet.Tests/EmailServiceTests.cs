using System.Net;
using backend_dotnet.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace backend_dotnet.Tests;

public class EmailServiceTests
{
    [Fact]
    public async Task MissingApiKey_DoesNotCallApi_ReturnsFalse()
    {
        var handler = new RecordingHandler();
        var service = CreateService(handler, new Dictionary<string, string?>());

        var sent = await service.SendAccountDecisionAsync("person@example.com", "Person", true);

        Assert.False(sent);
        Assert.Null(handler.LastRequest);
    }

    [Fact]
    public async Task ConfiguredService_PostsApiMessage()
    {
        var handler = new RecordingHandler { ResponseStatus = HttpStatusCode.Accepted };
        var service = CreateService(handler, new Dictionary<string, string?>
        {
            ["BrevoApi:ApiKey"] = "test-key",
            ["BrevoApi:SenderEmail"] = "placement@example.edu"
        });

        var sent = await service.SendAccountDecisionAsync("person@example.com", "Person", true);

        Assert.True(sent);
        Assert.Equal("https://api.brevo.com/v3/smtp/email", handler.LastRequest?.RequestUri?.ToString());
        Assert.Equal("test-key", handler.LastRequest?.Headers.GetValues("api-key").First());
        Assert.Contains("person@example.com", handler.LastBody);
    }

    [Fact]
    public async Task ShortlistApproval_EmailsStudentAboutFurtherReview()
    {
        var handler = new RecordingHandler { ResponseStatus = HttpStatusCode.Accepted };
        var service = CreateService(handler, new Dictionary<string, string?>
        {
            ["BrevoApi:ApiKey"] = "test-key",
            ["BrevoApi:SenderEmail"] = "placement@example.edu"
        });

        var sent = await service.SendCompanyShortlistApprovedAsync("student@example.edu", "Student", "Example Company", "Engineering Intern");

        Assert.True(sent);
        Assert.Contains("student@example.edu", handler.LastBody);
        Assert.Contains("approved for the shortlist and sent for further review", handler.LastBody);
    }

    private static BrevoEmailService CreateService(RecordingHandler handler, Dictionary<string, string?> settings)
    {
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(settings).Build();
        return new BrevoEmailService(new TestHttpClientFactory(new HttpClient(handler)).CreateClient(""), configuration, NullLogger<BrevoEmailService>.Instance);
    }

    private sealed class TestHttpClientFactory(HttpClient client) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => client;
    }

    private sealed class RecordingHandler : HttpMessageHandler
    {
        public HttpRequestMessage? LastRequest { get; private set; }
        public string LastBody { get; private set; } = string.Empty;
        public HttpStatusCode ResponseStatus { get; init; } = HttpStatusCode.OK;

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            LastRequest = request;
            LastBody = request.Content is null ? string.Empty : await request.Content.ReadAsStringAsync(cancellationToken);
            return new HttpResponseMessage(ResponseStatus);
        }
    }
}
