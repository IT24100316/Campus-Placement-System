using Microsoft.AspNetCore.Mvc;
using backend_dotnet.Services;

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
}
