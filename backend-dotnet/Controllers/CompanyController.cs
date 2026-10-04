using System;
using System.Threading.Tasks;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CompanyController : ControllerBase
{
    private readonly ICompanyService _companyService;

    public CompanyController(ICompanyService companyService)
    {
        _companyService = companyService;
    }

    /// <summary>
    /// Retrieve company profile, stats, active drives, and shortlisted candidates from DB
    /// </summary>
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile([FromQuery] string? email, [FromQuery] Guid? companyId)
    {
        var dashboard = await _companyService.GetCompanyDashboardAsync(email, companyId);

        if (dashboard == null)
        {
            return NotFound(new { message = "No company profile found in database." });
        }

        return Ok(dashboard);
    }

    /// <summary>
    /// Delete a job drive by ID
    /// </summary>
    [HttpDelete("jobs/{jobId}")]
    public async Task<IActionResult> DeleteJob(Guid jobId)
    {
        var success = await _companyService.DeleteJobAsync(jobId);
        if (!success)
        {
            return NotFound(new { message = "Job not found." });
        }

        return Ok(new { message = "Job deleted successfully." });
    }

    /// <summary>
    /// Update a job drive by ID
    /// </summary>
    [HttpPut("jobs/{jobId}")]
    public async Task<IActionResult> UpdateJob(Guid jobId, [FromBody] backend_dotnet.DTOs.UpdateJobDto dto)
    {
        var success = await _companyService.UpdateJobAsync(jobId, dto);
        if (!success)
        {
            return NotFound(new { message = "Job not found." });
        }

        return Ok(new { message = "Job updated successfully." });
    }

    /// <summary>
    /// Update a company HR profile (name, industry, contact, phone)
    /// </summary>
    [HttpPut("profile/{companyId}")]
    public async Task<IActionResult> UpdateProfile(Guid companyId, [FromBody] backend_dotnet.DTOs.UpdateCompanyProfileDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var success = await _companyService.UpdateProfileAsync(companyId, dto);
        if (!success)
            return NotFound(new { message = "Company profile not found." });

        return Ok(new { message = "Profile updated successfully." });
    }

    /// <summary>
    /// Delete a company HR profile and user account
    /// </summary>
    [HttpDelete("profile/{companyId}")]
    public async Task<IActionResult> DeleteProfile(Guid companyId)
    {
        var success = await _companyService.DeleteProfileAsync(companyId);
        if (!success)
            return NotFound(new { message = "Company profile not found." });

        return Ok(new { message = "Profile and account deleted successfully." });
    }
}
