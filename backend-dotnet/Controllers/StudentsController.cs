using System.Security.Claims;
using System.Text.RegularExpressions;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudentsController : ControllerBase
{
    private static readonly TimeSpan CvReplacementCooldown = TimeSpan.FromDays(7);
    private readonly AppDbContext _context;
    private readonly ICvFileValidationService _cvFileValidationService;
    private readonly ICvStorageService _cvStorageService;
    private readonly ILogger<StudentsController> _logger;
    private readonly INotificationService? _notificationService;

    public StudentsController(
        AppDbContext context,
        ICvFileValidationService cvFileValidationService,
        ICvStorageService cvStorageService,
        ILogger<StudentsController> logger,
        INotificationService? notificationService = null)
    {
        _context = context;
        _cvFileValidationService = cvFileValidationService;
        _cvStorageService = cvStorageService;
        _logger = logger;
        _notificationService = notificationService;
    }

    [HttpGet("profile")]
    [Authorize(Roles = "Student")]
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
                CvPdfUrl = candidate.CvPdfUrl,
                CvUploadedAt = candidate.CvUploadedAt,
                IsLookingForInternship = candidate.IsLookingForInternship
            })
            .SingleOrDefaultAsync();

        if (profile == null)
        {
            return NotFound(new { message = "Student profile not found." });
        }

        profile.CvNextEligibleUploadAt = profile.CvUploadedAt?
            .ToUniversalTime()
            .Add(CvReplacementCooldown);

        return Ok(profile);
    }

    [HttpPut("profile/internship-status")]
    [Authorize(Roles = "Student")]
    public async Task<IActionResult> UpdateInternshipStatus([FromBody] UpdateInternshipStatusDto dto)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized(new { message = "An authenticated student identity is required." });
        }

        var profile = await _context.StudentProfiles.SingleOrDefaultAsync(p => p.UserId == userId);
        if (profile == null)
        {
            return NotFound(new { message = "Student profile not found." });
        }

        profile.IsLookingForInternship = dto.IsLookingForInternship;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Internship status updated successfully", isLookingForInternship = profile.IsLookingForInternship });
    }

    [HttpPost("upload-cv")]
    [Authorize(Roles = "Student")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadCv(
        IFormFile? file,
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

        if (!IsCompleteForInternshipRegistration(profile))
        {
            return BadRequest(new { message = "Complete the required internship profile fields before uploading a CV." });
        }

        var previousStorageKey = profile.CvPdfUrl;
        var uploadedAtUtc = profile.CvUploadedAt?.ToUniversalTime();
        var nextEligibleUploadAt = uploadedAtUtc?.Add(CvReplacementCooldown);
        if (!string.IsNullOrWhiteSpace(previousStorageKey)
            && nextEligibleUploadAt.HasValue
            && DateTime.UtcNow < nextEligibleUploadAt.Value)
        {
            return Conflict(new
            {
                message = $"You can update your CV again on {nextEligibleUploadAt.Value:yyyy-MM-dd HH:mm:ss} UTC.",
                nextEligibleUploadAt = nextEligibleUploadAt.Value
            });
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

        profile.CvPdfUrl = storageKey;
        var newUploadedAtUtc = DateTime.UtcNow;
        profile.CvUploadedAt = newUploadedAtUtc;
        _notificationService?.Clear(userId, "cv_replacement_available");
        _notificationService?.Add(
            userId,
            "cv_uploaded",
            "CV uploaded",
            "Your CV was uploaded successfully. You can replace it again after seven days.",
            "resume");
        _notificationService?.AddIfMissing(
            userId,
            "resume_complete",
            "Resume complete",
            "Your profile and CV are ready for internship opportunities.",
            "resume");

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
            try
            {
                await _cvStorageService.DeleteAsync(previousStorageKey, CancellationToken.None);
            }
            catch (Exception exception)
            {
                // The new key is already committed; old-object cleanup must not
                // report the completed upload as a failure to the student.
                _logger.LogWarning(exception, "Failed to clean up the previous student CV after replacement.");
            }
        }

        return Ok(new
        {
            message = "CV uploaded successfully.",
            cvStorageKey = storageKey,
            cvUploadedAt = newUploadedAtUtc,
            cvNextEligibleUploadAt = newUploadedAtUtc.Add(CvReplacementCooldown)
        });
    }

    [HttpPut("profile")]
    [Authorize(Roles = "Student")]
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

        var wasComplete = profile != null && IsCompleteForInternshipRegistration(profile);

        profile ??= new StudentProfile
        {
            UserId = userId
        };

        var enteredValueError = ValidateEnteredValues(request);
        if (enteredValueError != null)
        {
            return BadRequest(new { message = enteredValueError });
        }

        ApplyProfileUpdates(profile, request);
        var isComplete = IsCompleteForInternshipRegistration(profile);

        if (!request.IsDraft && !IsValidForInternshipRegistration(profile))
        {
            return BadRequest(new
            {
                message = "Complete all required internship registration fields with valid values before submitting."
            });
        }

        if (isNewProfile)
        {
            _context.StudentProfiles.Add(profile);
        }

        if (!wasComplete && isComplete)
        {
            _notificationService?.AddIfMissing(
                userId,
                "profile_complete",
                "Profile complete",
                "Your internship profile is complete. Upload your CV to finish your resume.",
                "resume");
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
        profile.FullName = request.FullName?.Trim() ?? string.Empty;
        profile.Phone = request.Phone?.Trim() ?? string.Empty;
        profile.CampusIdPhotoUrl = request.CampusIdPhotoUrl?.Trim() ?? string.Empty;
        profile.PortfolioUrl = request.PortfolioUrl?.Trim();
        profile.UniversityName = request.UniversityName?.Trim() ?? string.Empty;
        profile.AcademicStatus = request.AcademicStatus?.Trim() ?? string.Empty;
        profile.DegreeProgram = request.DegreeProgram?.Trim() ?? string.Empty;
        profile.CurrentYearOfStudy = request.CurrentYearOfStudy ?? 0;
        profile.GPA = request.GPA ?? 0;
        profile.ExpectedGraduationDate = request.ExpectedGraduationDate;
        profile.DesiredJobTitle = request.DesiredJobTitle?.Trim() ?? string.Empty;
        profile.PrimaryDomain = request.PrimaryDomain?.Trim() ?? string.Empty;
        profile.CareerObjectivesSummary = request.CareerObjectivesSummary?.Trim() ?? string.Empty;
        profile.Skills = CleanItems(request.Skills);
        profile.ToolsAndTechnologies = CleanItems(request.ToolsAndTechnologies);
        profile.InternshipType = CleanItems(request.InternshipType);
        profile.LectureScheduleType = request.LectureScheduleType?.Trim() ?? string.Empty;
        profile.PreferredLocations = CleanItems(request.PreferredLocations);
    }

    private static bool IsValidForInternshipRegistration(StudentProfile profile)
    {
        return IsCompleteForInternshipRegistration(profile)
            && IsValidFullName(profile.FullName)
            && IsValidSriLankanMobile(profile.Phone)
            && profile.CampusIdPhotoUrl.Length <= 2048
            && IsValidPortfolioUrl(profile.PortfolioUrl)
            && IsValidUniversityName(profile.UniversityName)
            && profile.AcademicStatus.Length <= 100
            && profile.DegreeProgram.Length <= 255
            && profile.DesiredJobTitle.Length <= 255
            && profile.PrimaryDomain.Length <= 150
            && IsValidCareerObjective(profile.CareerObjectivesSummary)
            && HasValidDistinctItems(profile.Skills)
            && HasValidDistinctItems(profile.ToolsAndTechnologies)
            && profile.LectureScheduleType.Length <= 100;
    }

    private static bool IsCompleteForInternshipRegistration(StudentProfile profile)
    {
        return !string.IsNullOrWhiteSpace(profile.FullName)
            && !string.IsNullOrWhiteSpace(profile.Phone)
            && !string.IsNullOrWhiteSpace(profile.UniversityName)
            && !string.IsNullOrWhiteSpace(profile.AcademicStatus)
            && !string.IsNullOrWhiteSpace(profile.DegreeProgram)
            && profile.CurrentYearOfStudy is >= 1 and <= 8
            && profile.GPA is >= 0 and <= 4
            && profile.ExpectedGraduationDate?.Date >= DateTime.UtcNow.Date
            && !string.IsNullOrWhiteSpace(profile.DesiredJobTitle)
            && !string.IsNullOrWhiteSpace(profile.PrimaryDomain)
            && !string.IsNullOrWhiteSpace(profile.CareerObjectivesSummary)
            && profile.Skills.Any(skill => !string.IsNullOrWhiteSpace(skill))
            && profile.ToolsAndTechnologies.Any(tool => !string.IsNullOrWhiteSpace(tool))
            && profile.InternshipType.Any(type => !string.IsNullOrWhiteSpace(type))
            && !string.IsNullOrWhiteSpace(profile.LectureScheduleType)
            && profile.PreferredLocations.Any(location => !string.IsNullOrWhiteSpace(location));
    }

    private static string[] CleanItems(IEnumerable<string>? items)
    {
        return (items ?? Array.Empty<string>())
            .Select(item => item.Trim())
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .ToArray();
    }

    private static string? ValidateEnteredValues(StudentProfileUpsertRequest request)
    {
        if (HasText(request.FullName) && !IsValidFullName(request.FullName!))
            return "Enter a valid full name using 2 to 100 letters, spaces, hyphens, or apostrophes.";
        if (HasText(request.Phone) && !IsValidSriLankanMobile(request.Phone!))
            return "Enter a valid Sri Lankan mobile number, for example 0771234567.";
        if (HasText(request.UniversityName) && !IsValidUniversityName(request.UniversityName!))
            return "Enter a valid university name using 2 to 255 characters.";
        if (HasText(request.PortfolioUrl) && !IsValidPortfolioUrl(request.PortfolioUrl))
            return "Enter a valid HTTPS portfolio URL.";
        if (HasText(request.CareerObjectivesSummary) && !IsValidCareerObjective(request.CareerObjectivesSummary!))
            return "Career objectives must be between 20 and 1000 characters.";
        if (request.CurrentYearOfStudy.HasValue && request.CurrentYearOfStudy is < 1 or > 8)
            return "Select a year of study from 1 to 8.";
        if (request.GPA.HasValue && request.GPA is < 0 or > 4)
            return "Enter a GPA from 0.00 to 4.00.";
        if (request.ExpectedGraduationDate.HasValue && request.ExpectedGraduationDate.Value.Date < DateTime.UtcNow.Date)
            return "Expected graduation date cannot be in the past.";
        if (!HasValidDistinctItems(request.Skills))
            return "Skills cannot contain empty or duplicate items.";
        if (!HasValidDistinctItems(request.ToolsAndTechnologies))
            return "Tools cannot contain empty or duplicate items.";
        return null;
    }

    private static bool HasText(string? value) => !string.IsNullOrWhiteSpace(value);

    private static bool IsValidFullName(string value)
    {
        var trimmed = value.Trim();
        return trimmed.Length is >= 2 and <= 100
            && Regex.IsMatch(trimmed, @"^[\p{L}\p{M}]+(?:[ '\-][\p{L}\p{M}]+)*$");
    }

    private static bool IsValidSriLankanMobile(string value) =>
        Regex.IsMatch(value.Trim(), @"^(?:07\d{8}|\+947\d{8})$");

    private static bool IsValidUniversityName(string value)
    {
        var trimmed = value.Trim();
        return trimmed.Length is >= 2 and <= 255
            && !trimmed.Any(char.IsControl)
            && Regex.IsMatch(trimmed, @"\p{L}");
    }

    private static bool IsValidPortfolioUrl(string? value)
    {
        if (!HasText(value)) return true;
        return Uri.TryCreate(value!.Trim(), UriKind.Absolute, out var uri)
            && uri.Scheme == Uri.UriSchemeHttps
            && !string.IsNullOrWhiteSpace(uri.Host);
    }

    private static bool IsValidCareerObjective(string value)
    {
        var length = value.Trim().Length;
        return length is >= 20 and <= 1000;
    }

    private static bool HasValidDistinctItems(IEnumerable<string>? items)
    {
        if (items == null) return true;
        var values = items.ToArray();
        return values.All(HasText)
            && values.Select(item => item.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).Count() == values.Length;
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
            CvPdfUrl = profile.CvPdfUrl,
            CvUploadedAt = profile.CvUploadedAt,
            CvNextEligibleUploadAt = profile.CvUploadedAt?.ToUniversalTime().Add(CvReplacementCooldown)
        };
    }

    [HttpGet("directory")]
    [Authorize(Roles = "Company,Staff,Admin")]
    public async Task<ActionResult<PaginatedResult<StudentProfileResponse>>> GetStudentDirectory(
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        IQueryable<StudentProfile> query = _context.StudentProfiles.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.ToLower().Trim();
            query = query.Where(sp => 
                sp.FullName.ToLower().Contains(s) || 
                sp.UniversityName.ToLower().Contains(s) || 
                sp.Skills.Any(skill => skill.ToLower().Contains(s))
            );
        }

        var totalCount = await query.CountAsync();

        var students = await query
            .OrderBy(sp => sp.FullName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(sp => new StudentProfileResponse
            {
                UserId = sp.UserId,
                FullName = sp.FullName,
                Phone = sp.Phone,
                CampusIdPhotoUrl = sp.CampusIdPhotoUrl,
                PortfolioUrl = sp.PortfolioUrl,
                UniversityName = sp.UniversityName,
                AcademicStatus = sp.AcademicStatus,
                DegreeProgram = sp.DegreeProgram,
                CurrentYearOfStudy = sp.CurrentYearOfStudy,
                GPA = sp.GPA,
                ExpectedGraduationDate = sp.ExpectedGraduationDate,
                DesiredJobTitle = sp.DesiredJobTitle,
                PrimaryDomain = sp.PrimaryDomain,
                CareerObjectivesSummary = sp.CareerObjectivesSummary,
                Skills = sp.Skills,
                ToolsAndTechnologies = sp.ToolsAndTechnologies,
                InternshipType = sp.InternshipType,
                LectureScheduleType = sp.LectureScheduleType,
                PreferredLocations = sp.PreferredLocations,
                CvPdfUrl = sp.CvPdfUrl,
                CvUploadedAt = sp.CvUploadedAt
            })
            .ToListAsync();

        var result = new PaginatedResult<StudentProfileResponse>
        {
            Items = students,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };

        return Ok(result);
    }

    private bool TryGetCurrentUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        return User.Identity?.IsAuthenticated == true
            && Guid.TryParse(claimValue, out userId);
    }
}
