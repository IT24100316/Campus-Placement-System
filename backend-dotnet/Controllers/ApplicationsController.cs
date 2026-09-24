using Microsoft.AspNetCore.Mvc;
using backend_dotnet.Services;
using backend_dotnet.DTOs;
using System.Security.Claims;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ApplicationsController : ControllerBase
{
    private readonly IApplicationService _applicationService;

    public ApplicationsController(IApplicationService applicationService)
    {
        _applicationService = applicationService;
    }

    /// <summary>Runs Agent 4 CV validation and pauses the workflow for administrator review.</summary>
    [HttpPost("{appId:guid}/evaluate")]
    public async Task<IActionResult> Evaluate(Guid appId, [FromBody] EvaluateApplicationDto request, CancellationToken cancellationToken)
    {
        try { return Ok(await _applicationService.EvaluateAsync(appId, request, cancellationToken)); }
        catch (KeyNotFoundException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
        catch (HttpRequestException ex) { return StatusCode(502, new { message = ex.Message }); }
    }

    /// <summary>Lists Agent 4 results paused for administrator approval.</summary>
    [HttpGet("pending-admin-approval")]
    public async Task<IActionResult> PendingAdminApproval(CancellationToken cancellationToken) =>
        Ok(await _applicationService.GetPendingAdminApprovalAsync(cancellationToken));

    [HttpPost("{appId:guid}/admin-approve")]
    public async Task<IActionResult> AdminApprove(Guid appId, CancellationToken cancellationToken) =>
        await AdminDecision(appId, true, cancellationToken);

    [HttpPost("{appId:guid}/admin-reject")]
    public async Task<IActionResult> AdminReject(Guid appId, CancellationToken cancellationToken) =>
        await AdminDecision(appId, false, cancellationToken);

    [HttpGet("student/{studentId:guid}")]
    public async Task<IActionResult> StudentApplications(Guid studentId, CancellationToken cancellationToken) =>
        Ok(await _applicationService.GetStudentApplicationsAsync(studentId, cancellationToken));

    private async Task<IActionResult> AdminDecision(Guid appId, bool approved, CancellationToken cancellationToken)
    {
        try
        {
            var application = await _applicationService.AdminDecisionAsync(appId, approved, cancellationToken);
            return Ok(new { applicationId = application.AppId, status = application.Status.ToString(), workflowResumed = approved });
        }
        catch (KeyNotFoundException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    /// <summary>
    /// Submits an internship application for the authenticated student.
    /// </summary>
    [HttpPost("apply")]
    public async Task<IActionResult> Apply(
        [FromBody] StudentApplicationSubmissionRequestDto request,
        CancellationToken cancellationToken)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (User.Identity?.IsAuthenticated != true ||
            !Guid.TryParse(claimValue, out var studentId) || studentId == Guid.Empty)
        {
            return Unauthorized(new { message = "An authenticated student identity is required." });
        }

        if (request.JobId is not { } jobId || jobId == Guid.Empty)
        {
            return BadRequest(new { message = "A valid job ID is required." });
        }

        try
        {
            var response = await _applicationService.SubmitStudentApplicationAsync(
                studentId, jobId, cancellationToken);
            return StatusCode(StatusCodes.Status201Created, response);
        }
        catch (StudentApplicationSubmissionException exception)
        {
            var error = new { message = exception.Message };
            return exception.Error switch
            {
                StudentApplicationSubmissionError.Unauthorized => Unauthorized(error),
                StudentApplicationSubmissionError.Forbidden => StatusCode(StatusCodes.Status403Forbidden, error),
                StudentApplicationSubmissionError.JobNotFound => NotFound(error),
                StudentApplicationSubmissionError.Duplicate or StudentApplicationSubmissionError.ExpiredJob => Conflict(error),
                _ => BadRequest(error)
            };
        }
    }

    /// <summary>
    /// Retrieves a paginated list of applications for a specific job, optionally filtered by status.
    /// </summary>
    [HttpGet("job/{jobId}")]
    public async Task<IActionResult> GetApplicationsByJobId(Guid jobId, [FromQuery] int page = 1, [FromQuery] string? status = null)
    {
        var result = await _applicationService.GetApplicationsByJobIdAsync(jobId, page, status);
        return Ok(result);
    }

    /// <summary>
    /// Searches for applications based on a provided query string.
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> SearchApplications([FromQuery] string query)
    {
        var result = await _applicationService.SearchApplicationsAsync(query);
        return Ok(result);
    }

    /// <summary>
    /// Updates the status of a specific application.
    /// </summary>
    [HttpPut("{appId}/status")]
    public async Task<IActionResult> UpdateApplicationStatus(Guid appId, [FromBody] UpdateStatusRequestDto request)
    {
        try
        {
            await _applicationService.UpdateApplicationStatusAsync(appId, request);
            return Ok(new { message = "Status updated successfully" });
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
    /// Schedules an interview for a specific application.
    /// </summary>
    [HttpPut("{appId}/interview")]
    public async Task<IActionResult> ScheduleInterview(Guid appId, [FromBody] ScheduleInterviewRequestDto request)
    {
        try
        {
            await _applicationService.ScheduleInterviewAsync(appId, request);
            return Ok(new { message = "Interview scheduled successfully" });
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
    /// Retrieves the CV download URL for a specific application.
    /// </summary>
    [HttpGet("{appId}/cv")]
    public async Task<IActionResult> GetCvDownloadUrl(Guid appId)
    {
        try
        {
            var url = await _applicationService.GetCvDownloadUrlAsync(appId);
            return Ok(new { cvUrl = url });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
