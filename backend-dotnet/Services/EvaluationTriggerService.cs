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
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();

        // Fetch pending applications
        var pendingApplications = await context.Applications
            .Where(a => a.Status == ApplicationStatus.Pending)
            .ToListAsync(stoppingToken);

        if (!pendingApplications.Any())
        {
            return;
        }

        _logger.LogInformation($"Found {pendingApplications.Count} pending applications. Processing as batches...");

        foreach (var application in pendingApplications)
        {
            // Lock as Processing
            application.Status = ApplicationStatus.Processing;
        }

        await context.SaveChangesAsync(stoppingToken);

        var aiBaseUrl = (configuration["AiService:BaseUrl"] ?? "http://127.0.0.1:8000").TrimEnd('/');

        // Group by JobId for Batch Processing
        var applicationsByJob = pendingApplications.GroupBy(a => a.JobId);

        foreach (var jobGroup in applicationsByJob)
        {
            var jobId = jobGroup.Key;
            var studentIds = jobGroup.Select(a => a.StudentId.ToString()).ToList();

            try
            {
                var body = JsonSerializer.Serialize(new
                {
                    job_id = jobId.ToString(),
                    student_ids = studentIds
                });

                var client = httpClientFactory.CreateClient();
                // Send batch to Python's LangGraph Orchestrator
                var response = await client.PostAsync($"{aiBaseUrl}/analyze", 
                    new StringContent(body, Encoding.UTF8, "application/json"), stoppingToken);

                if (!response.IsSuccessStatusCode)
                {
                    throw new HttpRequestException($"AI Service returned {response.StatusCode}.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to trigger batch evaluation for Job {jobId}");
                foreach (var app in jobGroup)
                {
                    app.Status = ApplicationStatus.Evaluation_Failed;
                    app.SummaryReport = JsonSerializer.Serialize(new { error = ex.Message });
                }
            }
        }

        // Save any failures that happened during trigger
        await context.SaveChangesAsync(stoppingToken);
    }
}
