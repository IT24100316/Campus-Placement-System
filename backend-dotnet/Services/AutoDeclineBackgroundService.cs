using backend_dotnet.Data;
using backend_dotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Services;

public class AutoDeclineBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AutoDeclineBackgroundService> _logger;

    public AutoDeclineBackgroundService(IServiceProvider serviceProvider, ILogger<AutoDeclineBackgroundService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Auto-Decline Background Service is starting.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessExpiredApplicationsAsync(stoppingToken);
                await NotifyEligibleCvReplacementsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while processing expired applications.");
            }

            // Check every 1 minute for expired applications
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }

    private async Task ProcessExpiredApplicationsAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var expiredApplications = await context.Applications
            .Where(a => a.Status == ApplicationStatus.Admin_Approved &&
                        a.DecisionDeadline.HasValue && 
                        a.DecisionDeadline.Value < DateTime.UtcNow)
            .ToListAsync(cancellationToken);

        if (expiredApplications.Any())
        {
            foreach (var app in expiredApplications)
            {
                app.Status = ApplicationStatus.Rejected;
                _logger.LogInformation("Auto-declined application {AppId} as deadline passed.", app.AppId);
            }

            await context.SaveChangesAsync(cancellationToken);
        }
    }

    private async Task NotifyEligibleCvReplacementsAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var eligibleStudents = await context.StudentProfiles
            .AsNoTracking()
            .Where(profile =>
                profile.CvUploadedAt.HasValue &&
                profile.CvUploadedAt.Value <= DateTime.UtcNow.AddDays(-7) &&
                !context.Notifications.Any(notification =>
                    notification.UserId == profile.UserId &&
                    notification.Type == "cv_replacement_available"))
            .Select(profile => profile.UserId)
            .ToListAsync(cancellationToken);

        foreach (var studentId in eligibleStudents)
        {
            notificationService.AddIfMissing(
                studentId,
                "cv_replacement_available",
                "CV update available",
                "You can now upload a newer CV if you need to update it.",
                "resume");
        }
        if (eligibleStudents.Count > 0) await context.SaveChangesAsync(cancellationToken);
    }
}
