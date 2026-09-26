using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.DTOs;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class JobsController : ControllerBase
{
    private readonly IJobService _jobService;

    public JobsController(IJobService jobService)
    {
        _jobService = jobService;
    }

    /// <summary>
    /// Retrieve all controlled Target Domains from the database
    /// </summary>
    [HttpGet("reference/domains")]
    public async Task<ActionResult<IEnumerable<TargetDomainDto>>> GetTargetDomains()
    {
        var domains = await _jobService.GetTargetDomainsAsync();
        return Ok(domains);
    }

    /// <summary>
    /// Retrieve Job Titles filtered by Target Domain from the database
    /// </summary>
    [HttpGet("reference/titles")]
    public async Task<ActionResult<IEnumerable<JobTitleDto>>> GetJobTitles(
        [FromQuery] int? domainId,
        [FromQuery] string? domain)
    {
        var titles = await _jobService.GetJobTitlesAsync(domainId, domain);
        return Ok(titles);
    }

    /// <summary>
    /// Retrieve controlled Internship Types strictly from backend enum (OnSite, Hybrid, Remote)
    /// </summary>
    [HttpGet("reference/internship-types")]
    public ActionResult<IEnumerable<string>> GetInternshipTypes()
    {
        var types = _jobService.GetInternshipTypes();
        return Ok(types);
    }

    /// <summary>
    /// Submit and save a new Job Posting to Supabase database
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> CreateJob([FromBody] CreateJobRequestDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var result = await _jobService.CreateJobAsync(request);

        if (!result.Success)
        {
            return BadRequest(new
            {
                error = result.ErrorTitle,
                message = result.ErrorMessage
            });
        }

        return StatusCode(201, result.Job);
    }

    /// <summary>
    /// Retrieve a paginated feed of jobs with filters (for mobile app)
    /// </summary>
    [HttpGet("feed")]
    public async Task<ActionResult<PaginatedResult<JobFeedDto>>> GetJobFeed(
        [FromQuery] string? search,
        [FromQuery] string? skills,
        [FromQuery] string? domain,
        [FromQuery] string[]? workArrangements,
        [FromQuery] bool? isPaidOnly,
        [FromQuery] bool? isEligible,
        [FromQuery] string? sortBy,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        // Extract student ID from token if we want to check eligibility
        Guid? studentId = null;
        if (isEligible == true)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (Guid.TryParse(userIdClaim, out var parsedId))
            {
                studentId = parsedId;
            }
        }

        var feed = await _jobService.GetJobFeedAsync(search, skills, domain, workArrangements, isPaidOnly, isEligible, studentId, sortBy, page, pageSize);
        return Ok(feed);
    }

    /// <summary>
    /// Retrieve comprehensive details for a specific job
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<JobDetailsDto>> GetJobDetails(Guid id)
    {
        var job = await _jobService.GetJobDetailsAsync(id);
        if (job == null) return NotFound(new { message = "Job not found." });
        return Ok(job);
    }
}
