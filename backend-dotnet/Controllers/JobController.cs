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
}
