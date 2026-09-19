using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly PasswordHasher<User> _passwordHasher = new();

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

    /// <summary>
    /// Register a company employee directly from Admin cockpit into database
    /// </summary>
    [HttpPost("register-employee")]
    public async Task<IActionResult> RegisterEmployee([FromBody] AdminRegisterEmployeeDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower());
        if (emailExists)
            return BadRequest(new { message = "An account with this email address is already registered." });

        CompanyProfile? company = null;
        if (dto.CompanyId.HasValue && dto.CompanyId.Value != Guid.Empty)
        {
            company = await _context.CompanyProfiles.FirstOrDefaultAsync(c => c.UserId == dto.CompanyId.Value);
        }

        if (company == null && !string.IsNullOrWhiteSpace(dto.CompanyName))
        {
            company = await _context.CompanyProfiles.FirstOrDefaultAsync(c => c.CompanyName.ToLower() == dto.CompanyName.ToLower());
        }

        // Fallback: If still null, pick first existing company or auto-create company profile
        if (company == null)
        {
            company = await _context.CompanyProfiles.FirstOrDefaultAsync();
        }

        if (company == null)
        {
            var companyUser = new User
            {
                Id = Guid.NewGuid(),
                Email = "hr@" + (string.IsNullOrWhiteSpace(dto.CompanyName) ? "acmeglobal.tech" : dto.CompanyName.ToLower().Replace(" ", "") + ".com"),
                Role = UserRole.Company,
                Status = AccountStatus.Approved,
                CreatedAt = DateTime.UtcNow
            };
            companyUser.PasswordHash = _passwordHasher.HashPassword(companyUser, "Vanguard#2024Secure!");

            company = new CompanyProfile
            {
                UserId = companyUser.Id,
                CompanyName = string.IsNullOrWhiteSpace(dto.CompanyName) ? "Acme Global Technologies Inc." : dto.CompanyName.Trim(),
                Industry = "Enterprise Technology & Engineering",
                ContactPersonName = "Corporate Representative",
                ContactPersonEmail = companyUser.Email,
                Phone = "+1 555-019-2834",
                BusinessRegistrationDocumentUrl = "Acme_Incorporation_BR.pdf"
            };

            _context.Users.Add(companyUser);
            _context.CompanyProfiles.Add(company);
            await _context.SaveChangesAsync();
        }

        var staffUser = new User
        {
            Id = Guid.NewGuid(),
            Email = dto.Email.Trim().ToLower(),
            Role = UserRole.Company,
            Status = AccountStatus.Approved,
            CreatedAt = DateTime.UtcNow
        };

        var pwd = string.IsNullOrWhiteSpace(dto.Password) ? "StaffPass@2025!" : dto.Password;
        staffUser.PasswordHash = _passwordHasher.HashPassword(staffUser, pwd);

        var staffProfile = new CompanyStaffProfile
        {
            UserId = staffUser.Id,
            CompanyId = company.UserId,
            FullName = dto.FullName.Trim(),
            StaffId = dto.StaffId.Trim(),
            JobPosition = string.IsNullOrWhiteSpace(dto.JobPosition) ? "Recruiter" : dto.JobPosition.Trim()
        };

        _context.Users.Add(staffUser);
        _context.CompanyStaffProfiles.Add(staffProfile);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Employee successfully registered and saved to database.",
            userId = staffUser.Id,
            fullName = staffProfile.FullName,
            email = staffUser.Email,
            companyName = company.CompanyName,
            companyId = company.UserId,
            staffId = staffProfile.StaffId,
            jobPosition = staffProfile.JobPosition,
            status = staffUser.Status.ToString()
        });
    }
}
