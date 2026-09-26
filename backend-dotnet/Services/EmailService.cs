using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace backend_dotnet.Services;

public interface IEmailService
{
    Task<bool> SendAccountDecisionAsync(string recipient, string displayName, bool approved, CancellationToken cancellationToken = default);
    Task<bool> SendInterviewScheduledAsync(string toEmail, string studentName, string companyName, string jobTitle, DateTime interviewDate, TimeSpan interviewTime, string? meetingLink, CancellationToken cancellationToken = default);
}

public sealed class SendGridEmailService : IEmailService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SendGridEmailService> _logger;

    public SendGridEmailService(HttpClient httpClient, IConfiguration configuration, ILogger<SendGridEmailService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
        _httpClient.BaseAddress = new Uri("https://api.sendgrid.com/v3/");
    }

    public Task<bool> SendAccountDecisionAsync(string recipient, string displayName, bool approved, CancellationToken cancellationToken = default)
    {
        var subject = approved ? "Your CampusAI account was approved" : "Update on your CampusAI registration";
        var action = approved
            ? "Your account is approved. You can now sign in to CampusAI."
            : "Your registration was not approved. Contact the placement office if you believe this is an error.";
        return SendAsync(recipient, displayName, subject, action, null, cancellationToken);
    }

    public Task<bool> SendInterviewScheduledAsync(
        string toEmail, 
        string studentName, 
        string companyName, 
        string jobTitle, 
        DateTime interviewDate, 
        TimeSpan interviewTime, 
        string? meetingLink, 
        CancellationToken cancellationToken = default)
    {
        var interviewDateTime = new DateTime(interviewDate.Year, interviewDate.Month, interviewDate.Day, 
                                             interviewTime.Hours, interviewTime.Minutes, interviewTime.Seconds);

        var subject = $"Interview Invitation – {jobTitle} at {companyName}";
        
        var htmlContent = $@"
            <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333;'>
                <h2>Interview Invitation</h2>
                <p>Dear <strong>{studentName}</strong>,</p>
                <p>We are pleased to inform you that you have been selected for an interview for the <strong>{jobTitle}</strong> position at <strong>{companyName}</strong>.</p>
                
                <div style='background-color: #f4f7f6; padding: 15px; border-radius: 8px; margin: 20px 0;'>
                    <h3 style='margin-top: 0;'>Interview Details</h3>
                    <ul style='list-style-type: none; padding-left: 0;'>
                        <li style='margin-bottom: 10px;'>📅 <strong>Date:</strong> {interviewDateTime:dd MMMM yyyy}</li>
                        <li style='margin-bottom: 10px;'>⏰ <strong>Time:</strong> {interviewDateTime:hh:mm tt}</li>
                        <li>📍 <strong>Location / Link:</strong> {meetingLink ?? "Online / Details to follow"}</li>
                    </ul>
                </div>

                <p>Your interview has been scheduled for the above date and time. Please attend the interview at the scheduled time.</p>
                <p>A calendar invitation (.ics) has been attached to this email so you can seamlessly add the interview to your calendar.</p>
                <p>If you have any questions or concerns regarding the interview, please reply directly to this email.</p>
                
                <p style='margin-top: 30px; font-size: 0.9em; color: #666;'>
                    Best regards,<br/>
                    <strong>{companyName}</strong>
                </p>
            </div>
        ";

        var icsContent = GenerateIcsContent(companyName, jobTitle, interviewDateTime, meetingLink);
        var icsBase64 = Convert.ToBase64String(Encoding.UTF8.GetBytes(icsContent));
        
        var attachment = new 
        {
            content = icsBase64,
            type = "text/calendar",
            filename = "invite.ics",
            disposition = "attachment"
        };

        return SendAsync(toEmail, studentName, subject, htmlContent, attachment, cancellationToken, isHtml: true, fromNameOverride: companyName);
    }

    private async Task<bool> SendAsync(string recipient, string displayName, string subject, string body, object? attachment, CancellationToken cancellationToken, bool isHtml = false, string? fromNameOverride = null)
    {
        // Try new config first, fallback to old config
        var apiKey = _configuration["SendGridApi:ApiKey"] ?? _configuration["SendGrid:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey) || apiKey == "YOUR_SENDGRID_API_KEY_HERE")
        {
            _logger.LogWarning("SendGrid API Key is not configured. Email to {Recipient} was not sent.", recipient);
            return false;
        }

        var fromEmail = _configuration["SendGridApi:SenderEmail"] ?? _configuration["SendGrid:FromEmail"] ?? "noreply@campusai.local";
        // If an override is provided (like the company name), use it. Otherwise fallback to config.
        var fromName = fromNameOverride ?? _configuration["SendGridApi:SenderName"] ?? _configuration["SendGrid:FromName"] ?? "CampusAI";
        
        var contentArray = isHtml 
            ? new[] { new { type = "text/html", value = body } } 
            : new[] { new { type = "text/plain", value = $"Hello {displayName},\n\n{body}\n\nCampusAI Placement Office" } };

        var payload = new
        {
            personalizations = new[] { new { to = new[] { new { email = recipient, name = displayName } } } },
            from = new { email = fromEmail, name = fromName },
            subject,
            content = contentArray,
            attachments = attachment != null ? new[] { attachment } : null
        };

        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        var jsonContent = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        try
        {
            // Polly handles retries automatically
            var response = await _httpClient.PostAsync("mail/send", jsonContent, cancellationToken);
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
    
    private string GenerateIcsContent(string companyName, string jobTitle, DateTime startDateTime, string? meetingLink)
    {
        var endDateTime = startDateTime.AddHours(1);
        var timeStamp = DateTime.UtcNow.ToString("yyyyMMddTHHmmssZ");
        
        var startFormat = startDateTime.ToUniversalTime().ToString("yyyyMMddTHHmmssZ");
        var endFormat = endDateTime.ToUniversalTime().ToString("yyyyMMddTHHmmssZ");
        var location = !string.IsNullOrEmpty(meetingLink) ? meetingLink : "Online";

        var sb = new StringBuilder();
        sb.AppendLine("BEGIN:VCALENDAR");
        sb.AppendLine("VERSION:2.0");
        sb.AppendLine("PRODID:-//Campus Placement System//EN");
        sb.AppendLine("CALSCALE:GREGORIAN");
        sb.AppendLine("METHOD:PUBLISH");
        sb.AppendLine("BEGIN:VEVENT");
        sb.AppendLine($"DTSTAMP:{timeStamp}");
        sb.AppendLine($"DTSTART:{startFormat}");
        sb.AppendLine($"DTEND:{endFormat}");
        sb.AppendLine($"SUMMARY:Interview: {jobTitle} at {companyName}");
        sb.AppendLine($"LOCATION:{location}");
        sb.AppendLine($"DESCRIPTION:Interview for the {jobTitle} position at {companyName}.");
        sb.AppendLine($"UID:{Guid.NewGuid()}@campusplacement.edu");
        sb.AppendLine("STATUS:CONFIRMED");
        sb.AppendLine("END:VEVENT");
        sb.AppendLine("END:VCALENDAR");

        return sb.ToString();
    }
}
