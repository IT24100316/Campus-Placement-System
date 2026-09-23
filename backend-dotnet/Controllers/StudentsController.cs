using System.Security.Claims;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudentsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ICvFileValidationService _cvFileValidationService;
    private readonly ICvStorageService _cvStorageService;

    public StudentsController(
        AppDbContext context,
        ICvFileValidationService cvFileValidationService,
        ICvStorageService cvStorageService)
    {
        _context = context;
        _cvFileValidationService = cvFileValidationService;
        _cvStorageService = cvStorageService;
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

    [HttpPost("upload-cv")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadCv(
        [FromForm] IFormFile? file,
        CancellationToken cancellationToken)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized(new { message = "An authenticated student identity is required." });
        }

        var user = await _context.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(candidate => candidate.Id == userId, cancellationToken);

        if (user == null)
        {
            return Unauthorized(new { message = "The authenticated user no longer exists." });
        }

        if (user.Role != UserRole.Student)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new
            {
                message = "Only student accounts can upload a CV."
            });
        }

        var profile = await _context.StudentProfiles
            .SingleOrDefaultAsync(candidate => candidate.UserId == userId, cancellationToken);
        if (profile == null)
        {
            return NotFound(new { message = "Save the student profile before uploading a CV." });
        }

        var validation = await _cvFileValidationService.ValidateAsync(file, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(new { message = validation.ErrorMessage });
        }

        string storageKey;
        try
        {
            storageKey = await _cvStorageService.StoreAsync(userId, file!, cancellationToken);
        }
        catch (Exception)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                message = "Unable to store the CV at this time."
            });
        }

        var previousStorageKey = profile.CvPdfUrl;
        profile.CvPdfUrl = storageKey;

        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            await _cvStorageService.DeleteAsync(storageKey, CancellationToken.None);
            return Conflict(new { message = "The student profile was changed concurrently. Please try again." });
        }
        catch (Exception)
        {
            await _cvStorageService.DeleteAsync(storageKey, CancellationToken.None);
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                message = "Unable to save the CV reference at this time."
            });
        }

        if (!string.IsNullOrWhiteSpace(previousStorageKey))
        {
            await _cvStorageService.DeleteAsync(previousStorageKey, CancellationToken.None);
        }

        return Ok(new
        {
            message = "CV uploaded successfully.",
            cvStorageKey = storageKey
        });
    }

    [HttpPut("profile")]
    public async Task<IActionResult> SaveProfile([FromBody] StudentProfileUpsertRequest request)
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
                message = "Only student accounts can save a student profile."
            });
        }

        var profile = await _context.StudentProfiles
            .SingleOrDefaultAsync(candidate => candidate.UserId == userId);
        var isNewProfile = profile == null;

        profile ??= new StudentProfile
        {
            UserId = userId
        };

        ApplyProfileUpdates(profile, request);

        if (isNewProfile)
        {
            _context.StudentProfiles.Add(profile);
        }

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Conflict(new { message = "The student profile was changed concurrently. Please try again." });
        }
        catch (Exception)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                message = "Unable to save the student profile at this time."
            });
        }

        var response = ToResponse(profile);
        return isNewProfile
            ? CreatedAtAction(nameof(GetProfile), response)
            : Ok(response);
    }

    private static void ApplyProfileUpdates(StudentProfile profile, StudentProfileUpsertRequest request)
    {
        profile.FullName = request.FullName.Trim();
        profile.Phone = request.Phone.Trim();
        profile.CampusIdPhotoUrl = request.CampusIdPhotoUrl.Trim();
        profile.PortfolioUrl = request.PortfolioUrl?.Trim();
        profile.UniversityName = request.UniversityName.Trim();
        profile.AcademicStatus = request.AcademicStatus.Trim();
        profile.DegreeProgram = request.DegreeProgram.Trim();
        profile.CurrentYearOfStudy = request.CurrentYearOfStudy;
        profile.GPA = request.GPA;
        profile.ExpectedGraduationDate = request.ExpectedGraduationDate;
        profile.DesiredJobTitle = request.DesiredJobTitle.Trim();
        profile.PrimaryDomain = request.PrimaryDomain.Trim();
        profile.CareerObjectivesSummary = request.CareerObjectivesSummary.Trim();
        profile.Skills = CleanItems(request.Skills);
        profile.ToolsAndTechnologies = CleanItems(request.ToolsAndTechnologies);
        profile.InternshipType = CleanItems(request.InternshipType);
        profile.LectureScheduleType = request.LectureScheduleType.Trim();
        profile.PreferredLocations = CleanItems(request.PreferredLocations);
    }

    private static string[] CleanItems(IEnumerable<string> items)
    {
        return items
            .Select(item => item.Trim())
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .ToArray();
    }

    private static StudentProfileResponse ToResponse(StudentProfile profile)
    {
        return new StudentProfileResponse
        {
            UserId = profile.UserId,
            FullName = profile.FullName,
            Phone = profile.Phone,
            CampusIdPhotoUrl = profile.CampusIdPhotoUrl,
            PortfolioUrl = profile.PortfolioUrl,
            UniversityName = profile.UniversityName,
            AcademicStatus = profile.AcademicStatus,
            DegreeProgram = profile.DegreeProgram,
            CurrentYearOfStudy = profile.CurrentYearOfStudy,
            GPA = profile.GPA,
            ExpectedGraduationDate = profile.ExpectedGraduationDate,
            DesiredJobTitle = profile.DesiredJobTitle,
            PrimaryDomain = profile.PrimaryDomain,
            CareerObjectivesSummary = profile.CareerObjectivesSummary,
            Skills = profile.Skills,
            ToolsAndTechnologies = profile.ToolsAndTechnologies,
            InternshipType = profile.InternshipType,
            LectureScheduleType = profile.LectureScheduleType,
            PreferredLocations = profile.PreferredLocations,
            CvPdfUrl = profile.CvPdfUrl
        };
    }

    private bool TryGetCurrentUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        return User.Identity?.IsAuthenticated == true
            && Guid.TryParse(claimValue, out userId);
    }
}
