using Microsoft.AspNetCore.Mvc;
using backend_dotnet.Services;
using backend_dotnet.DTOs;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ApplicationsController : ControllerBase
{
    private readonly IApplicationService _applicationService;
    private readonly IConfiguration _configuration;

    public ApplicationsController(IApplicationService applicationService, IConfiguration configuration)
    {
        _applicationService = applicationService;
        _configuration = configuration;
    }

    /// <summary>Creates a pending job application for an approved student.</summary>
    [HttpPost("apply")]
    public async Task<IActionResult> Apply([FromBody] ApplyForJobDto request, CancellationToken cancellationToken)
    {
        try
        {
            var application = await _applicationService.ApplyAsync(request, cancellationToken);
            return Ok(new { applicationId = application.AppId, status = application.Status.ToString() });
        }
        catch (KeyNotFoundException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    /// <summary>Webhook endpoint for Python Agent 3 to return evaluation results.</summary>
    [HttpPost("webhook/evaluation-result")]
    public async Task<IActionResult> EvaluationWebhook([FromBody] WebhookEvaluationResultDto payload, CancellationToken cancellationToken)
    {
        var configuredSecret = _configuration["Webhook:Secret"];
        if (!Request.Headers.TryGetValue("x-webhook-secret", out var providedSecret) || providedSecret != configuredSecret)
        {
            return Unauthorized(new { message = "Invalid or missing webhook secret." });
        }

        try 
        { 
            await _applicationService.HandleEvaluationWebhookAsync(payload, cancellationToken);
            return Ok(new { message = "Webhook processed successfully." }); 
        }
        catch (KeyNotFoundException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
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
