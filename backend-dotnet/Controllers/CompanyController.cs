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
}
