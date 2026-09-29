using System.Security.Claims;
using backend_dotnet.DTOs;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ApplicationsController : ControllerBase
{
    private readonly IApplicationService _applicationService;
    private readonly IConfiguration _configuration;

    public ApplicationsController(
        IApplicationService applicationService,
        IConfiguration configuration)
    {
        _applicationService = applicationService;
        _configuration = configuration;
    }


    // Called when a student hits the apply button. It handles the request and creates a new pending application!
    [HttpPost("apply")]
    public async Task<IActionResult> Apply(
        [FromBody] ApplyForJobDto request,
        CancellationToken cancellationToken)
    {
        try
        {
            var application = await _applicationService.ApplyAsync(
                request,
                cancellationToken);

            return Ok(new
            {
                applicationId = application.AppId,
                status = application.Status.ToString()
            });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    // The webhook where Python Agent 3 posts the AI evaluation results.
    // It requires a secret token to ensure only our AI engine can hit it.
    [HttpPost("webhook/evaluation-result")]
    public async Task<IActionResult> EvaluationWebhook(
        [FromBody] WebhookEvaluationResultDto payload,
        CancellationToken cancellationToken)
    {
        var configuredSecret = _configuration["Webhook:Secret"];

        if (string.IsNullOrWhiteSpace(configuredSecret))
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new { message = "The webhook is not configured." });
        }

        if (!Request.Headers.TryGetValue(
                "x-webhook-secret",
                out var providedSecret) ||
            providedSecret != configuredSecret)
        {
            return Unauthorized(new
            {
                message = "Invalid or missing webhook secret."
            });
        }

        try
        {
            await _applicationService.HandleEvaluationWebhookAsync(
                payload,
                cancellationToken);

            return Ok(new
            {
                message = "Webhook processed successfully."
            });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    // Fetches all the applications that the AI has processed and are now waiting for human university admin approval.
    [Authorize(Roles = "Admin")]
    [HttpGet("pending-admin-approval")]
    public async Task<IActionResult> PendingAdminApproval(
        CancellationToken cancellationToken)
    {
        var applications =
            await _applicationService.GetPendingAdminApprovalAsync(
                cancellationToken);

        return Ok(applications);
    }

    public class HumanVerifyRequest
    {
        public Guid AppId { get; set; }
        public bool Approved { get; set; }
    }

    // This is the bridge endpoint used by the React UI for admins to approve/reject an application.
    // After saving the decision, it pings the Python AI to wake it up and resume the background workflow!
    [Authorize(Roles = "Admin")]
    [HttpPost("human-verify")]
    public async Task<IActionResult> HumanVerify(
        [FromBody] HumanVerifyRequest request,
        [FromServices] IHttpClientFactory httpClientFactory,
        [FromServices] IConfiguration configuration,
        [FromServices] backend_dotnet.Data.AppDbContext dbContext,
        CancellationToken cancellationToken)
    {
        // 0. Guard against pending memos (Approval Blocker)
        if (request.Approved)
        {
            var hasPendingMemos = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.AnyAsync(
                dbContext.Memos, m => m.ApplicationId == request.AppId && m.Status == "Pending", cancellationToken);
            if (hasPendingMemos)
            {
                return BadRequest(new { message = "Cannot approve. Please resolve all internal memos first." });
            }
        }

        var applicationIds = await dbContext.Applications
            .Where(a => a.AppId == request.AppId)
            .Select(a => new { a.JobId, a.StudentId })
            .FirstOrDefaultAsync(cancellationToken);
        if (applicationIds == null) return NotFound(new { message = "Application not found." });

        // 1. First, process the local Admin Decision 
        try
        {
            await _applicationService.AdminDecisionAsync(request.AppId, request.Approved, cancellationToken);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }

        return await ResumeWorkflowAsync(applicationIds.JobId, applicationIds.StudentId, request.Approved,
            httpClientFactory, configuration, cancellationToken);
    }

    /// <summary>Retries the AI continuation after an administrator decision was saved but delivery failed.</summary>
    [Authorize(Roles = "Admin")]
    [HttpPost("{appId:guid}/retry-workflow-resume")]
    public async Task<IActionResult> RetryWorkflowResume(
        Guid appId,
        [FromServices] IHttpClientFactory httpClientFactory,
        [FromServices] IConfiguration configuration,
        [FromServices] backend_dotnet.Data.AppDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var application = await dbContext.Applications
            .Where(a => a.AppId == appId)
            .Select(a => new { a.JobId, a.StudentId, a.Status })
            .FirstOrDefaultAsync(cancellationToken);
        if (application == null) return NotFound(new { message = "Application not found." });
        if (application.Status is not (backend_dotnet.Models.ApplicationStatus.Admin_Approved or backend_dotnet.Models.ApplicationStatus.Rejected))
            return Conflict(new { message = "No saved administrator decision can be resumed." });
        return await ResumeWorkflowAsync(application.JobId, application.StudentId,
            application.Status == backend_dotnet.Models.ApplicationStatus.Admin_Approved,
            httpClientFactory, configuration, cancellationToken);
    }

    private async Task<IActionResult> ResumeWorkflowAsync(
        Guid jobId, Guid studentId, bool approved,
        IHttpClientFactory httpClientFactory, IConfiguration configuration,
        CancellationToken cancellationToken)
    {
        // Forward the saved decision to the one-candidate paused workflow.
        var reviewerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(reviewerId))
            return Unauthorized(new { message = "An administrator identity is required." });
        var aiBaseUrl = (configuration["AiService:BaseUrl"] ?? "http://127.0.0.1:8000").TrimEnd('/');
        var client = httpClientFactory.CreateClient();
        
        var body = System.Text.Json.JsonSerializer.Serialize(new
        {
            thread_id = $"{jobId}:{studentId}",
            human_approved = approved,
            approved_by = reviewerId,
            decision_at = DateTime.UtcNow.ToString("O")
        });

        try
        {
            using var resume = new HttpRequestMessage(HttpMethod.Post, $"{aiBaseUrl}/resume")
            {
                Content = new StringContent(body, System.Text.Encoding.UTF8, "application/json")
            };
            var secret = configuration["Webhook:Secret"];
            if (string.IsNullOrWhiteSpace(secret))
                return StatusCode(503, new { message = "Decision saved; workflow credential is not configured.", workflowResumed = false });
            resume.Headers.Add("x-webhook-secret", secret);
            using var response = await client.SendAsync(resume, cancellationToken);
            if (!response.IsSuccessStatusCode)
                return StatusCode(502, new { message = "Decision saved; the AI workflow could not resume.", workflowResumed = false });
            using var result = await System.Text.Json.JsonDocument.ParseAsync(
                await response.Content.ReadAsStreamAsync(cancellationToken), cancellationToken: cancellationToken);
            if (!result.RootElement.TryGetProperty("email_sent", out var emailSent) || emailSent.ValueKind != System.Text.Json.JsonValueKind.True)
                return StatusCode(502, new { message = "Decision saved; the final notification was not confirmed.", workflowResumed = false });
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or System.Text.Json.JsonException)
        {
            Console.WriteLine($"Warning: Failed to resume Python graph for job {jobId}, student {studentId}. {ex.Message}");
            return StatusCode(502, new { message = "Decision saved; the AI workflow could not resume.", workflowResumed = false });
        }

        return Ok(new { message = "Decision processed and AI resumed." });
    }

    // Gets all applications for a given student ID. Useful for admin or staff views.
    [HttpGet("student/{studentId:guid}")]
    public async Task<IActionResult> StudentApplications(
        Guid studentId,
        CancellationToken cancellationToken)
    {
        var applications =
            await _applicationService.GetStudentApplicationsAsync(
                studentId,
                cancellationToken);

        return Ok(applications);
    }

    // Gets the current logged-in student's applications so they can see their own status on the dashboard.
    [HttpGet("me")]
    [Authorize(Roles = "Student")]
    public async Task<IActionResult> MyApplications(
        CancellationToken cancellationToken)
    {
        var claimValue =
            User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (User.Identity?.IsAuthenticated != true ||
            !Guid.TryParse(claimValue, out var studentId) ||
            studentId == Guid.Empty)
        {
            return Unauthorized(new
            {
                message =
                    "An authenticated student identity is required."
            });
        }

        var applications =
            await _applicationService.GetStudentApplicationsAsync(
                studentId,
                cancellationToken);

        return Ok(applications);
    }

    // Grabs a paginated list of all applications for a specific job posting.
    [HttpGet("job/{jobId:guid}")]
    public async Task<IActionResult> GetApplicationsByJobId(
        Guid jobId,
        [FromQuery] int page = 1,
        [FromQuery] string? status = null)
    {
        var applications =
            await _applicationService.GetApplicationsByJobIdAsync(
                jobId,
                page,
                status!);

        return Ok(applications);
    }

    // Allows searching for applications using a simple text query.
    [HttpGet("search")]
    public async Task<IActionResult> SearchApplications(
        [FromQuery] string query)
    {
        var applications =
            await _applicationService.SearchApplicationsAsync(query);

        return Ok(applications);
    }

    // Returns the count of all action-required memos (used for the staff notification bell).
    [HttpGet("memos/action-required/count")]
    public async Task<IActionResult> GetActionRequiredMemosCount(
        [FromServices] backend_dotnet.Data.AppDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var count = await dbContext.Memos
            .CountAsync(m => m.Status == "Pending", cancellationToken);

        return Ok(new { count = count });
    }



    // Fetches the direct URL to download a student's CV for a specific application.
    [HttpGet("{appId:guid}/cv")]
    public async Task<IActionResult> GetCvDownloadUrl(Guid appId)
    {
        try
        {
            var url =
                await _applicationService.GetCvDownloadUrlAsync(appId);

            return Ok(new { cvUrl = url });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    // A private helper that actually talks to the service layer to save an admin's approve/reject decision.
    private async Task<IActionResult> AdminDecision(
        Guid appId,
        bool approved,
        CancellationToken cancellationToken)
    {
        try
        {
            var application =
                await _applicationService.AdminDecisionAsync(
                    appId,
                    approved,
                    cancellationToken);

            return Ok(new
            {
                applicationId = application.AppId,
                status = application.Status.ToString(),
                workflowResumed = approved
            });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    // When a student happily accepts a job offer!
    [HttpPost("{appId:guid}/student-accept")]
    [Authorize(Roles = "Student")]
    public Task<IActionResult> StudentAccept(
        Guid appId,
        CancellationToken cancellationToken)
    {
        return StudentDecision(appId, true, cancellationToken);
    }

    // When a student declines a job offer.
    [HttpPost("{appId:guid}/student-decline")]
    [Authorize(Roles = "Student")]
    public Task<IActionResult> StudentDecline(
        Guid appId,
        CancellationToken cancellationToken)
    {
        return StudentDecision(appId, false, cancellationToken);
    }

    // A private helper that saves the student's final accept/decline decision.
    private async Task<IActionResult> StudentDecision(
        Guid appId,
        bool accepted,
        CancellationToken cancellationToken)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (User.Identity?.IsAuthenticated != true || !Guid.TryParse(claimValue, out var studentId) || studentId == Guid.Empty)
            return Unauthorized(new { message = "An authenticated student identity is required." });

        try
        {
            var application = await _applicationService.StudentDecisionAsync(appId, studentId, accepted, cancellationToken);
            return Ok(new
            {
                applicationId = application.AppId,
                status = application.Status.ToString()
            });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }
}