using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly PasswordHasher<User> _passwordHasher = new();

    public AuthController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Authenticate User (Admin, Company HR, Company Staff)
    /// </summary>
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var user = await _context.Users
            .Include(u => u.CompanyProfile)
            .Include(u => u.CompanyStaffProfile)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower());

        if (user == null)
            return Unauthorized(new { message = "Invalid email or password credentials." });

        var verifyResult = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
        if (verifyResult == PasswordVerificationResult.Failed)
            return Unauthorized(new { message = "Invalid email or password credentials." });

        // Check pending approval
        if (user.Status == AccountStatus.Pending)
        {
            return Ok(new
            {
                success = false,
                isPending = true,
                message = "Your registration application is currently under administrative review.",
                role = user.Role.ToString(),
                status = user.Status.ToString(),
                email = user.Email
            });
        }

        if (user.Status == AccountStatus.Rejected)
        {
            return StatusCode(403, new
            {
                success = false,
                message = "Your account application has been declined by the administrator."
            });
        }

        return Ok(new
        {
            success = true,
            email = user.Email,
            role = user.Role.ToString(),
            status = user.Status.ToString(),
            message = "Authentication successful."
        });
    }

    /// <summary>
    /// Register as Company HR (Creates User + CompanyProfile with Pending status)
    /// </summary>
    [HttpPost("register-hr")]
    public async Task<IActionResult> RegisterCompanyHr([FromBody] RegisterCompanyHrDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if email is already taken
        var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower());
        if (emailExists)
            return BadRequest(new { message = "Email is already registered in the system." });

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = dto.Email.Trim().ToLower(),
            Role = UserRole.Company,
            Status = AccountStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);

        var companyProfile = new CompanyProfile
        {
            UserId = user.Id,
            CompanyName = dto.CompanyName.Trim(),
            Industry = dto.Industry.Trim(),
            ContactPersonName = dto.FullName.Trim(),
            ContactPersonEmail = dto.Email.Trim().ToLower(),
            Phone = dto.Phone.Trim(),
            BusinessRegistrationDocumentUrl = string.IsNullOrWhiteSpace(dto.BusinessRegistrationDocumentUrl)
                ? "sample_br_doc.pdf"
                : dto.BusinessRegistrationDocumentUrl
        };

        _context.Users.Add(user);
        _context.CompanyProfiles.Add(companyProfile);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Company HR registered successfully. Awaiting administrator approval.",
            userId = user.Id,
            companyName = companyProfile.CompanyName,
            status = user.Status.ToString()
        });
    }

    /// <summary>
    /// Register as Company Staff (Links to existing CompanyProfile with Pending status)
    /// </summary>
    [HttpPost("register-staff")]
    public async Task<IActionResult> RegisterCompanyStaff([FromBody] RegisterCompanyStaffDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if email exists
        var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower());
        if (emailExists)
            return BadRequest(new { message = "Email is already registered in the system." });

        // Check company exists
        var company = await _context.CompanyProfiles.FirstOrDefaultAsync(c => c.UserId == dto.CompanyId);
        if (company == null)
            return NotFound(new { message = "Selected employer company not found." });

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = dto.Email.Trim().ToLower(),
            Role = UserRole.Company,
            Status = AccountStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);

        var staffProfile = new CompanyStaffProfile
        {
            UserId = user.Id,
            CompanyId = company.UserId,
            FullName = dto.FullName.Trim(),
            StaffId = dto.StaffId.Trim(),
            JobPosition = dto.JobPosition.Trim()
        };

        _context.Users.Add(user);
        _context.CompanyStaffProfiles.Add(staffProfile);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Company Staff registered successfully. Awaiting administrator approval.",
            userId = user.Id,
            companyName = company.CompanyName,
            status = user.Status.ToString()
        });
    }

    /// <summary>
    /// Get list of recognized companies for Staff dropdown
    /// </summary>
    [HttpGet("companies")]
    public async Task<IActionResult> GetCompanies()
    {
        var companies = await _context.CompanyProfiles
            .Select(c => new ApprovedCompanyDto
            {
                Id = c.UserId,
                Name = c.CompanyName,
                Industry = c.Industry
            })
            .ToListAsync();

        return Ok(companies);
    }
}
