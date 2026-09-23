using System.Net;
using backend_dotnet.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace backend_dotnet.Tests;

public class EmailServiceTests
{
    [Fact]
    public async Task MissingApiKey_DoesNotCallSendGrid()
    {
        var handler = new RecordingHandler();
        var service = CreateService(handler, new Dictionary<string, string?>());

        var sent = await service.SendAccountDecisionAsync("person@example.com", "Person", true);

        Assert.False(sent);
        Assert.Null(handler.LastRequest);
    }

    [Fact]
    public async Task ConfiguredService_PostsSendGridMessage()
    {
        var handler = new RecordingHandler { ResponseStatus = HttpStatusCode.Accepted };
        var service = CreateService(handler, new Dictionary<string, string?>
        {
            ["SendGrid:ApiKey"] = "test-key",
            ["SendGrid:FromEmail"] = "placement@example.edu"
        });

        var sent = await service.SendAccountDecisionAsync("person@example.com", "Person", true);

        Assert.True(sent);
        Assert.Equal("https://api.sendgrid.com/v3/mail/send", handler.LastRequest?.RequestUri?.ToString());
        Assert.Equal("Bearer", handler.LastRequest?.Headers.Authorization?.Scheme);
        Assert.Contains("person@example.com", handler.LastBody);
    }

    private static SendGridEmailService CreateService(RecordingHandler handler, Dictionary<string, string?> settings)
    {
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(settings).Build();
        return new SendGridEmailService(new TestHttpClientFactory(new HttpClient(handler)), configuration, NullLogger<SendGridEmailService>.Instance);
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
