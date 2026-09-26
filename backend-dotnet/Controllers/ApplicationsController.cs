using System.Security.Claims;
using backend_dotnet.DTOs;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

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

    /// <summary>
    /// Runs Agent 4 CV validation and pauses the workflow for administrator review.
    /// </summary>
    [HttpPost("{appId:guid}/evaluate")]
    public async Task<IActionResult> Evaluate(
        Guid appId,
        [FromBody] EvaluateApplicationDto request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _applicationService.EvaluateAsync(
                appId,
                request,
                cancellationToken);

            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
        catch (HttpRequestException ex)
        {
            return StatusCode(
                StatusCodes.Status502BadGateway,
                new { message = ex.Message });
        }
    }

    /// <summary>
    /// Creates a pending job application for an approved student.
    /// </summary>
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

    /// <summary>
    /// Webhook endpoint for Python Agent 3 to return evaluation results.
    /// </summary>
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

    /// <summary>
    /// Lists Agent 4 results paused for administrator approval.
    /// </summary>
    [HttpGet("pending-admin-approval")]
    public async Task<IActionResult> PendingAdminApproval(
        CancellationToken cancellationToken)
    {
        var applications =
            await _applicationService.GetPendingAdminApprovalAsync(
                cancellationToken);

        return Ok(applications);
    }

    /// <summary>
    /// Approves an application and resumes its workflow.
    /// </summary>
    [HttpPost("{appId:guid}/admin-approve")]
    public Task<IActionResult> AdminApprove(
        Guid appId,
        CancellationToken cancellationToken)
    {
        return AdminDecision(
            appId,
            approved: true,
            cancellationToken);
    }

    /// <summary>
    /// Rejects an application during administrator review.
    /// </summary>
    [HttpPost("{appId:guid}/admin-reject")]
    public Task<IActionResult> AdminReject(
        Guid appId,
        CancellationToken cancellationToken)
    {
        return AdminDecision(
            appId,
            approved: false,
            cancellationToken);
    }

    /// <summary>
    /// Lists applications belonging to the specified student.
    /// </summary>
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

    /// <summary>
    /// Lists applications belonging to the authenticated student.
    /// </summary>
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

    /// <summary>
    /// Retrieves a paginated list of applications for a specific job.
    /// </summary>
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

    /// <summary>
    /// Searches for applications using the provided query.
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> SearchApplications(
        [FromQuery] string query)
    {
        var applications =
            await _applicationService.SearchApplicationsAsync(query);

        return Ok(applications);
    }

    /// <summary>
    /// Updates the status of an application.
    /// </summary>
    [HttpPut("{appId:guid}/status")]
    public async Task<IActionResult> UpdateApplicationStatus(
        Guid appId,
        [FromBody] UpdateStatusRequestDto request)
    {
        try
        {
            await _applicationService.UpdateApplicationStatusAsync(
                appId,
                request);

            return Ok(new
            {
                message = "Status updated successfully"
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

    /// <summary>
    /// Schedules an interview for an application.
    /// </summary>
    [HttpPut("{appId:guid}/interview")]
    public async Task<IActionResult> ScheduleInterview(
        Guid appId,
        [FromBody] ScheduleInterviewRequestDto request)
    {
        try
        {
            await _applicationService.ScheduleInterviewAsync(
                appId,
                request);

            return Ok(new
            {
                message = "Interview scheduled successfully"
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

    /// <summary>
    /// Retrieves the CV download URL for an application.
    /// </summary>
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
}