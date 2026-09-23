using System.Security.Claims;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudentsController : ControllerBase
{
    private readonly AppDbContext _context;

    public StudentsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized(new { message = "An authenticated student identity is required." });
        }

        var user = await _context.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(candidate => candidate.Id == userId);

        if (user == null)
        {
            return Unauthorized(new { message = "The authenticated user no longer exists." });
        }

        if (user.Role != UserRole.Student)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new
            {
                message = "Only student accounts can access a student profile."
            });
        }

        var profile = await _context.StudentProfiles
            .AsNoTracking()
            .Where(candidate => candidate.UserId == userId)
            .Select(candidate => new StudentProfileResponse
            {
                UserId = candidate.UserId,
                FullName = candidate.FullName,
                Phone = candidate.Phone,
                CampusIdPhotoUrl = candidate.CampusIdPhotoUrl,
                PortfolioUrl = candidate.PortfolioUrl,
                UniversityName = candidate.UniversityName,
                AcademicStatus = candidate.AcademicStatus,
                DegreeProgram = candidate.DegreeProgram,
                CurrentYearOfStudy = candidate.CurrentYearOfStudy,
                GPA = candidate.GPA,
                ExpectedGraduationDate = candidate.ExpectedGraduationDate,
                DesiredJobTitle = candidate.DesiredJobTitle,
                PrimaryDomain = candidate.PrimaryDomain,
                CareerObjectivesSummary = candidate.CareerObjectivesSummary,
                Skills = candidate.Skills,
                ToolsAndTechnologies = candidate.ToolsAndTechnologies,
                InternshipType = candidate.InternshipType,
                LectureScheduleType = candidate.LectureScheduleType,
                PreferredLocations = candidate.PreferredLocations,
                CvPdfUrl = candidate.CvPdfUrl
            })
            .SingleOrDefaultAsync();

        if (profile == null)
        {
            return NotFound(new { message = "Student profile not found." });
        }

        return Ok(profile);
    }

    private bool TryGetCurrentUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        return User.Identity?.IsAuthenticated == true
            && Guid.TryParse(claimValue, out userId);
    }
}
