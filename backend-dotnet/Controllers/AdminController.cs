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
    /// Approve an account by user ID or Email
    /// </summary>
    [HttpPost("approve/{identifier}")]
    public async Task<IActionResult> ApproveUser(string identifier)
    {
        User? user = null;
        if (Guid.TryParse(identifier, out var parsedGuid))
        {
            user = await _context.Users.Include(u => u.CompanyProfile).FirstOrDefaultAsync(u => u.Id == parsedGuid);
        }
        if (user == null)
        {
            var normalized = identifier.Trim().ToLower();
            user = await _context.Users.Include(u => u.CompanyProfile).FirstOrDefaultAsync(u => u.Email.ToLower() == normalized);
        }

        if (user == null)
            return NotFound(new { message = "User not found." });

        user.Status = AccountStatus.Approved;

        // Also ensure company has default placement jobs if none exist
        if (user.CompanyProfile != null && !_context.Jobs.Any(j => j.CompanyId == user.Id))
        {
            _context.Jobs.AddRange(
                new Job
                {
                    JobId = Guid.NewGuid(),
                    CompanyId = user.Id,
                    JobTitle = "Backend Engineering Co-op",
                    TargetDomain = "Distributed Systems & APIs • 6 Months",
                    JobDescriptionSummary = "Build and scale high-throughput cloud microservices.",
                    InternshipType = new[] { "Full-time", "Hybrid" },
                    LocationCity = "San Jose, CA",
                    MinimumGPA = 3.5m,
                    AllowedYearsOfStudy = new[] { 3, 4 },
                    MandatorySkills = new[] { "Python", "Go", "PostgreSQL" },
                    NiceToHaveSkills = new[] { "Docker", "Kubernetes" },
                    PreferredDegreePrograms = new[] { "B.S. Computer Science" },
                    StipendOffered = true,
                    StipendAmountOrDetails = "$45 / hr",
                    DurationMonths = 6,
                    ApplicationDeadline = DateTime.UtcNow.AddDays(45)
                },
                new Job
                {
                    JobId = Guid.NewGuid(),
                    CompanyId = user.Id,
                    JobTitle = "Associate Machine Learning Engineer",
                    TargetDomain = "AI Infrastructure • Class of 2025",
                    JobDescriptionSummary = "Train and deploy deep learning models and agentic workflows.",
                    InternshipType = new[] { "Full-time" },
                    LocationCity = "Austin, TX",
                    MinimumGPA = 3.6m,
                    AllowedYearsOfStudy = new[] { 4 },
                    MandatorySkills = new[] { "PyTorch", "CUDA", "Python" },
                    NiceToHaveSkills = new[] { "FastAPI", "LangChain" },
                    PreferredDegreePrograms = new[] { "M.S. Machine Learning", "B.S. CS" },
                    StipendOffered = true,
                    StipendAmountOrDetails = "$55 / hr",
                    DurationMonths = 6,
                    ApplicationDeadline = DateTime.UtcNow.AddDays(30)
                }
            );
        }

        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Account approved successfully in database.",
            userId = user.Id,
            email = user.Email,
            status = user.Status.ToString()
        });
    }

    /// <summary>
    /// Reject an account by user ID or Email
    /// </summary>
    [HttpPost("reject/{identifier}")]
    public async Task<IActionResult> RejectUser(string identifier)
    {
        User? user = null;
        if (Guid.TryParse(identifier, out var parsedGuid))
        {
            user = await _context.Users.FirstOrDefaultAsync(u => u.Id == parsedGuid);
        }
        if (user == null)
        {
            var normalized = identifier.Trim().ToLower();
            user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == normalized);
        }

        if (user == null)
            return NotFound(new { message = "User not found." });

        user.Status = AccountStatus.Rejected;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Account rejected in database.",
            userId = user.Id,
            email = user.Email,
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
        var defaultOrgName = string.IsNullOrWhiteSpace(dto.CompanyName) ? "CampusAI" : dto.CompanyName.Trim();

        if (dto.CompanyId.HasValue && dto.CompanyId.Value != Guid.Empty)
        {
            company = await _context.CompanyProfiles.FirstOrDefaultAsync(c => c.UserId == dto.CompanyId.Value);
        }

        if (company == null)
        {
            company = await _context.CompanyProfiles.FirstOrDefaultAsync(c => c.CompanyName.ToLower() == defaultOrgName.ToLower());
        }

        // Auto-provision platform web app company profile if not yet in database
        if (company == null)
        {
            var companyUser = new User
            {
                Id = Guid.NewGuid(),
                Email = "platform-ops@" + defaultOrgName.ToLower().Replace(" ", "") + ".edu",
                Role = UserRole.Company,
                Status = AccountStatus.Approved,
                CreatedAt = DateTime.UtcNow
            };
            companyUser.PasswordHash = _passwordHasher.HashPassword(companyUser, "CampusAI#2025Secure!");

            company = new CompanyProfile
            {
                UserId = companyUser.Id,
                CompanyName = defaultOrgName,
                Industry = "Platform & Campus Placement Operations",
                ContactPersonName = "Institutional Platform Operations",
                ContactPersonEmail = companyUser.Email,
                Phone = "+1 555-019-2834",
                BusinessRegistrationDocumentUrl = "CampusAI_Platform_Registration.pdf"
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
