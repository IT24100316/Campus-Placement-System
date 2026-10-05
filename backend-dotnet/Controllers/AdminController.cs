using backend_dotnet.DTOs;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _adminService;

    public AdminController(IAdminService adminService)
    {
        _adminService = adminService;
    }

    /// <summary>
    /// Retrieve all pending accounts for admin review
    /// </summary>
    [HttpGet("pending-approvals")]
    public async Task<IActionResult> GetPendingApprovals()
    {
        var pendingUsers = await _adminService.GetPendingApprovalsAsync();
        return Ok(pendingUsers);
    }

    /// <summary>
    /// Approve an account by user ID or Email
    /// </summary>
    [HttpPost("approve/{identifier}")]
    public async Task<IActionResult> ApproveUser(string identifier)
    {
        try
        {
            var result = await _adminService.ApproveUserAsync(identifier);
            return result == null ? NotFound(new { message = "User not found." }) : Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Reject an account by user ID or Email
    /// </summary>
    [HttpPost("reject/{identifier}")]
    public async Task<IActionResult> RejectUser(string identifier)
    {
        try
        {
            var result = await _adminService.RejectUserAsync(identifier);
            return result == null ? NotFound(new { message = "User not found." }) : Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Register a company employee directly from Admin cockpit into database
    /// </summary>
    [HttpPost("register-employee")]
    public async Task<IActionResult> RegisterEmployee([FromBody] AdminRegisterEmployeeDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var result = await _adminService.RegisterEmployeeAsync(dto);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
