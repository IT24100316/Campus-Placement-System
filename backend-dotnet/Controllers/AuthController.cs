using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using backend_dotnet.DTOs;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    /// <summary>Registers a student account using the existing User and StudentProfile entities.</summary>
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto dto, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        try
        {
            var result = await _authService.RegisterAsync(dto, cancellationToken);
            return Ok(new { message = result.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>Registers a student and stores the campus ID in the private verification document store.</summary>
    [HttpPost("register-student")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> RegisterStudent([FromForm] RegisterStudentFormDto dto, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        try
        {
            var result = await _authService.RegisterStudentAsync(dto, cancellationToken);
            return Ok(new { success = result.Success, result.UserId, result.Status, result.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Authenticate User (Admin, Company HR, Company Staff)
    /// </summary>
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var result = await _authService.LoginAsync(dto);

        if (result == null)
            return Unauthorized(new { message = "Invalid email or password credentials." });

        if (result.IsRejected)
        {
            return StatusCode(403, new
            {
                success = false,
                userId = result.UserId,
                message = result.Message
            });
        }

        if (result.IsPending)
        {
            return Ok(new
            {
                success = false,
                isPending = true,
                message = result.Message,
                role = result.Role,
                status = result.Status,
                email = result.Email,
                companyName = result.CompanyName,
                fullName = result.FullName,
                staffId = result.StaffId,
                jobPosition = result.JobPosition
            });
        }

        return Ok(new
        {
            success = true,
            token = result.Token,
            user = result.User,
            message = result.Message
        });
    }

    /// <summary>Returns the exact user identified by the JWT NameIdentifier claim.</summary>
    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me(CancellationToken cancellationToken)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { message = "The authentication token does not contain a valid user identifier." });

        var user = await _authService.GetUserAsync(userId, cancellationToken);
        if (user == null)
            return Unauthorized(new { message = "The authenticated user no longer exists." });

        return Ok(user);
    }

    /// <summary>
    /// Register as Company HR (Creates User + CompanyProfile with Pending status)
    /// </summary>
    [HttpPost("register-hr")]
    public async Task<IActionResult> RegisterCompanyHr([FromBody] RegisterCompanyHrDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var result = await _authService.RegisterCompanyHrAsync(dto);
            return Ok(new
            {
                success = result.Success,
                message = result.Message,
                userId = result.UserId,
                companyName = result.CompanyName,
                status = result.Status
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Register as Company Staff (Links to existing CompanyProfile with Pending status)
    /// </summary>
    [HttpPost("register-staff")]
    public async Task<IActionResult> RegisterCompanyStaff([FromBody] RegisterCompanyStaffDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var result = await _authService.RegisterCompanyStaffAsync(dto);
            return Ok(new
            {
                success = result.Success,
                message = result.Message,
                userId = result.UserId,
                companyName = result.CompanyName,
                status = result.Status
            });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Get list of recognized companies for Staff dropdown
    /// </summary>
    [HttpGet("companies")]
    public async Task<IActionResult> GetCompanies()
    {
        var companies = await _authService.GetCompaniesAsync();
        return Ok(companies);
    }
}
