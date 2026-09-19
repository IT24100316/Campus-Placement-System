using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Retrieve all pending accounts for admin review
    /// </summary>
    [HttpGet("pending-approvals")]
    public async Task<IActionResult> GetPendingApprovals()
    {
        var pendingUsers = await _context.Users
            .Include(u => u.CompanyProfile)
            .Include(u => u.CompanyStaffProfile)
                .ThenInclude(csp => csp!.Company)
            .Where(u => u.Role == UserRole.Company)
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new PendingUserDto
            {
                UserId = u.Id,
                Email = u.Email,
                FullName = u.CompanyProfile != null
                    ? u.CompanyProfile.ContactPersonName
                    : (u.CompanyStaffProfile != null ? u.CompanyStaffProfile.FullName : "Unknown"),
                Role = u.CompanyProfile != null ? "Company HR" : "Company Staff",
                Status = u.Status.ToString(),
                CompanyName = u.CompanyProfile != null
                    ? u.CompanyProfile.CompanyName
                    : (u.CompanyStaffProfile != null && u.CompanyStaffProfile.Company != null
                        ? u.CompanyStaffProfile.Company.CompanyName
                        : "N/A"),
                Industry = u.CompanyProfile != null ? u.CompanyProfile.Industry : null,
                Phone = u.CompanyProfile != null ? u.CompanyProfile.Phone : null,
                StaffId = u.CompanyStaffProfile != null ? u.CompanyStaffProfile.StaffId : null,
                JobPosition = u.CompanyStaffProfile != null ? u.CompanyStaffProfile.JobPosition : null,
                BusinessRegistrationDocumentUrl = u.CompanyProfile != null
                    ? u.CompanyProfile.BusinessRegistrationDocumentUrl
                    : null,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(pendingUsers);
    }

    /// <summary>
    /// Approve an account
    /// </summary>
    [HttpPost("approve/{userId}")]
    public async Task<IActionResult> ApproveUser(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
            return NotFound(new { message = "User not found." });

        user.Status = AccountStatus.Approved;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Account approved successfully.",
            userId = user.Id,
            status = user.Status.ToString()
        });
    }

    /// <summary>
    /// Reject an account
    /// </summary>
    [HttpPost("reject/{userId}")]
    public async Task<IActionResult> RejectUser(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
            return NotFound(new { message = "User not found." });

        user.Status = AccountStatus.Rejected;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Account rejected.",
            userId = user.Id,
            status = user.Status.ToString()
        });
    }
}
