using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using backend_dotnet.Data;
using backend_dotnet.Models;

namespace backend_dotnet.Services;

public class EvaluationTriggerService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<EvaluationTriggerService> _logger;

    public EvaluationTriggerService(IServiceScopeFactory scopeFactory, ILogger<EvaluationTriggerService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("EvaluationTriggerService is starting.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessPendingApplicationsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred executing EvaluationTriggerService.");
            }

            // Poll every 30 seconds
            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
        }

        _logger.LogInformation("EvaluationTriggerService is stopping.");
    }

    private async Task ProcessPendingApplicationsAsync(CancellationToken stoppingToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var httpClientFactory = scope.ServiceProvider.GetRequiredService<IHttpClientFactory>();
        var documentStorage = scope.ServiceProvider.GetRequiredService<IDocumentStorageService>();
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();

        // Fetch pending applications
        var pendingApplications = await context.Applications
            .Include(a => a.Student).ThenInclude(u => u.StudentProfile)
            .Where(a => a.Status == ApplicationStatus.Pending)
            .ToListAsync(stoppingToken);

        if (!pendingApplications.Any())
        {
            return;
        }

        _logger.LogInformation($"Found {pendingApplications.Count} pending applications. Processing...");

        foreach (var application in pendingApplications)
        {
            // Lock as Processing
            application.Status = ApplicationStatus.Processing;
        }

        await context.SaveChangesAsync(stoppingToken);

        var aiBaseUrl = (configuration["AiService:BaseUrl"] ?? "http://127.0.0.1:8000").TrimEnd('/');

        foreach (var application in pendingApplications)
        {
            try
            {
                var cvKey = application.Student.StudentProfile?.CvPdfUrl;
                if (string.IsNullOrWhiteSpace(cvKey))
                {
                    throw new InvalidOperationException("The student must upload a CV PDF before validation.");
                }

                string? cvPdfBase64 = null;
                if (cvKey.StartsWith("local://") || cvKey.StartsWith("supabase://"))
                {
                    var storedCv = await documentStorage.OpenReadAsync(cvKey, stoppingToken)
                        ?? throw new InvalidOperationException("The stored CV could not be read.");
                    using var memory = new MemoryStream();
                    await storedCv.Content.CopyToAsync(memory, stoppingToken);
                    cvPdfBase64 = Convert.ToBase64String(memory.ToArray());
                }

                var body = JsonSerializer.Serialize(new
                {
                    application_id = application.AppId,
                    summary = "", // Background evaluations don't take a user summary
                    cv_pdf_url = cvPdfBase64 is null ? cvKey : null,
                    cv_pdf_base64 = cvPdfBase64
                });

                var client = httpClientFactory.CreateClient();
                // We don't await the response to finish the heavy lifting, 
                // we just fire it and expect a 202 Accepted.
                var response = await client.PostAsync($"{aiBaseUrl}/validate", 
                    new StringContent(body, Encoding.UTF8, "application/json"), stoppingToken);

                if (!response.IsSuccessStatusCode)
                {
                    throw new HttpRequestException($"AI Service returned {response.StatusCode}.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to trigger evaluation for application {application.AppId}");
                application.Status = ApplicationStatus.Evaluation_Failed;
                application.SummaryReport = JsonSerializer.Serialize(new { error = ex.Message });
            }
        }

        // Save any failures that happened during trigger
        await context.SaveChangesAsync(stoppingToken);
    }
}
