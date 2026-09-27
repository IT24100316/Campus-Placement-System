using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.DTOs;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class JobsController : ControllerBase
{
    private readonly IJobService _jobService;
    private readonly IHttpClientFactory _httpClientFactory;

    public JobsController(IJobService jobService, IHttpClientFactory httpClientFactory)
    {
        _jobService = jobService;
        _httpClientFactory = httpClientFactory;
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

        // Fire-and-forget trigger to Python AI Matchmaker
        _ = Task.Run(async () => 
        {
            try 
            {
                var client = _httpClientFactory.CreateClient();
                var aiUrl = "http://127.0.0.1:8000/analyze";
                var payload = new { job_id = result.Job.JobId, student_ids = new List<string>(), evaluate_all = true };
                var json = System.Text.Json.JsonSerializer.Serialize(payload);
                var content = new System.Net.Http.StringContent(json, System.Text.Encoding.UTF8, "application/json");
                await client.PostAsync(aiUrl, content);
            }
            catch (Exception ex)
            {
                System.Console.WriteLine($"Failed to trigger AI on job publish: {ex.Message}");
            }
        });

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
        [FromQuery] decimal? minGpa,
        [FromQuery] decimal? maxGpa,
        [FromQuery] int[]? allowedYears,
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

        var feed = await _jobService.GetJobFeedAsync(search, skills, domain, workArrangements, isPaidOnly, isEligible, studentId, minGpa, maxGpa, allowedYears, sortBy, page, pageSize);
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

    /// <summary>
    /// Repost an existing job to trigger the AI matching pipeline again
    /// </summary>
    [HttpPost("{id}/repost")]
    [Authorize(Roles = "Company")]
    public async Task<ActionResult<JobCreationResultDto>> RepostJob(Guid id)
    {
        var result = await _jobService.RepostJobAsync(id);

        if (!result.Success)
        {
            return BadRequest(result);
        }

        // Trigger Python AI Service (Fire and Forget)
        _ = Task.Run(async () =>
        {
            try
            {
                using var client = _httpClientFactory.CreateClient();
                // Send the exact same payload as CreateJob, but the JobId is the existing one
                var aiPayload = new { job_id = result.Job?.JobId, evaluate_all = true };
                var response = await client.PostAsJsonAsync("http://127.0.0.1:8000/analyze", aiPayload);
                response.EnsureSuccessStatusCode();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[AI Pipeline Trigger Failed on Repost] {ex.Message}");
            }
        });

        return Ok(result);
    }
}
