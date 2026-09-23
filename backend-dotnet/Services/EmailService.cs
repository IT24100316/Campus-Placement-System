using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace backend_dotnet.Services;

public interface IEmailService
{
    Task<bool> SendAccountDecisionAsync(string recipient, string displayName, bool approved, CancellationToken cancellationToken = default);
    Task<bool> SendInterviewScheduledAsync(string recipient, string displayName, string jobTitle, DateTime interviewAt, CancellationToken cancellationToken = default);
}

public sealed class SendGridEmailService : IEmailService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SendGridEmailService> _logger;

    public SendGridEmailService(IHttpClientFactory httpClientFactory, IConfiguration configuration, ILogger<SendGridEmailService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public Task<bool> SendAccountDecisionAsync(string recipient, string displayName, bool approved, CancellationToken cancellationToken = default)
    {
        var subject = approved ? "Your CampusAI account was approved" : "Update on your CampusAI registration";
        var action = approved
            ? "Your account is approved. You can now sign in to CampusAI."
            : "Your registration was not approved. Contact the placement office if you believe this is an error.";
        return SendAsync(recipient, displayName, subject, action, cancellationToken);
    }

    public Task<bool> SendInterviewScheduledAsync(string recipient, string displayName, string jobTitle, DateTime interviewAt, CancellationToken cancellationToken = default) =>
        SendAsync(recipient, displayName, $"Interview scheduled: {jobTitle}",
            $"Your interview for {jobTitle} is scheduled for {interviewAt:dddd, dd MMMM yyyy 'at' HH:mm} UTC.", cancellationToken);

    private async Task<bool> SendAsync(string recipient, string displayName, string subject, string body, CancellationToken cancellationToken)
    {
        var apiKey = _configuration["SendGrid:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogWarning("SendGrid:ApiKey is not configured. Email to {Recipient} was not sent.", recipient);
            return false;
        }

        var fromEmail = _configuration["SendGrid:FromEmail"] ?? "noreply@campusai.local";
        var fromName = _configuration["SendGrid:FromName"] ?? "CampusAI";
        var payload = new
        {
            personalizations = new[] { new { to = new[] { new { email = recipient, name = displayName } } } },
            from = new { email = fromEmail, name = fromName },
            subject,
            content = new[] { new { type = "text/plain", value = $"Hello {displayName},\n\n{body}\n\nCampusAI Placement Office" } }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.sendgrid.com/v3/mail/send");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
        try
        {
            var response = await _httpClientFactory.CreateClient().SendAsync(request, cancellationToken);
            if (response.IsSuccessStatusCode) return true;
            _logger.LogError("SendGrid returned {StatusCode}: {Response}", response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
            return false;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "SendGrid request failed for {Recipient}.", recipient);
            return false;
        }
    }
}
