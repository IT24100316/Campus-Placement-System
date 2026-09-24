using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Npgsql;
using System.Text;
using System.Text.Json;

namespace backend_dotnet.Services;

public class ApplicationService : IApplicationService
{
    private readonly AppDbContext _context;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly IEmailService _emailService;
    private readonly IDocumentStorageService _documentStorage;

    public ApplicationService(
        AppDbContext context,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        IEmailService emailService,
        IDocumentStorageService documentStorage)
    {
        _context = context;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _emailService = emailService;
        _documentStorage = documentStorage;
    }

    public async Task<StudentApplicationSubmissionResponseDto> SubmitStudentApplicationAsync(
        Guid studentId, Guid jobId, CancellationToken cancellationToken)
    {
        var user = await _context.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(candidate => candidate.Id == studentId, cancellationToken);
        if (user == null)
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.Unauthorized,
                "The authenticated user no longer exists.");
        }

        if (user.Role != UserRole.Student)
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.Forbidden,
                "Only student accounts can apply for internships.");
        }

        var job = await _context.Jobs
            .AsNoTracking()
            .SingleOrDefaultAsync(candidate => candidate.JobId == jobId, cancellationToken);
        if (job == null)
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.JobNotFound,
                "The internship job was not found.");
        }

        if (job.ApplicationDeadline <= DateTime.UtcNow)
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.ExpiredJob,
                "The application deadline for this internship has passed.");
        }

        var profile = await _context.StudentProfiles
            .AsNoTracking()
            .SingleOrDefaultAsync(candidate => candidate.UserId == studentId, cancellationToken);
        if (profile == null)
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.InvalidProfile,
                "Save your student profile before applying for an internship.");
        }

        if (!IsCompleteForApplication(profile))
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.InvalidProfile,
                "Complete your student profile before applying for an internship.");
        }

        if (string.IsNullOrWhiteSpace(profile.CvPdfUrl))
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.InvalidProfile,
                "Upload your PDF CV before applying for an internship.");
        }

        if (await _context.Applications.AsNoTracking().AnyAsync(
            candidate => candidate.StudentId == studentId && candidate.JobId == jobId,
            cancellationToken))
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.Duplicate,
                "You have already applied for this internship.");
        }

        var application = new Application
        {
            StudentId = studentId,
            JobId = jobId,
            Status = ApplicationStatus.Pending,
            // Required schema values; AI scoring and summary are not processed yet.
            MatchScore = 0,
            SummaryReport = "{}"
        };
        _context.Applications.Add(application);

        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception) when (
            exception.InnerException is PostgresException postgresException &&
            postgresException.SqlState == PostgresErrorCodes.UniqueViolation &&
            postgresException.ConstraintName == "IX_Applications_StudentId_JobId")
        {
            throw new StudentApplicationSubmissionException(
                StudentApplicationSubmissionError.Duplicate,
                "You have already applied for this internship.");
        }

        return new StudentApplicationSubmissionResponseDto(
            application.AppId, application.JobId, application.Status.ToString());
    }

    private static bool IsCompleteForApplication(StudentProfile profile)
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
            && profile.Skills?.Any(skill => !string.IsNullOrWhiteSpace(skill)) == true
            && profile.ToolsAndTechnologies?.Any(tool => !string.IsNullOrWhiteSpace(tool)) == true
            && profile.InternshipType?.Any(type => !string.IsNullOrWhiteSpace(type)) == true
            && !string.IsNullOrWhiteSpace(profile.LectureScheduleType)
            && profile.PreferredLocations?.Any(location => !string.IsNullOrWhiteSpace(location)) == true;
    }


    /// <summary>
    /// GetApplicationsByJobIdAsync
    /// Fetches a paginated list of applications for a specific job, including the candidate's profile details.
    /// Optionally filters the applications by their current status.
    /// </summary>
    public async Task<IEnumerable<ApplicationResponseDto>> GetApplicationsByJobIdAsync(Guid jobId, int page, string status)
    {
        int pageSize = 10;
        
        var query = _context.Applications
            .Include(a => a.Student)
                .ThenInclude(u => u.StudentProfile)
            .Where(a => a.JobId == jobId);

        if (!string.IsNullOrEmpty(status) && Enum.TryParse<ApplicationStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(a => a.Status == parsedStatus);
        }

        var applications = await query
            .OrderByDescending(a => a.MatchScore)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return applications.Select(a => new ApplicationResponseDto(
            a.AppId,
            a.Student?.StudentProfile?.FullName ?? "Unknown Candidate",
            a.Student?.StudentProfile?.UniversityName ?? "Unknown University",
            a.MatchScore,
            string.IsNullOrWhiteSpace(a.SummaryReport) ? Array.Empty<string>() : a.SummaryReport.Split('\n', StringSplitOptions.RemoveEmptyEntries),
            a.Student?.StudentProfile?.CvPdfUrl ?? "",
            a.Status.ToString(),
            a.InterviewDate,
            a.InterviewTime
        ));
    }


    /// <summary>
    /// SearchApplicationsAsync
    /// Searches through all applications by matching the search query against the candidate's full name 
    /// or any of the skills listed in their profile.
    /// </summary>
    public async Task<IEnumerable<ApplicationResponseDto>> SearchApplicationsAsync(string query)
    {
        var lowerQuery = string.IsNullOrWhiteSpace(query) ? string.Empty : query.ToLower();

        var applications = await _context.Applications
            .Include(a => a.Student)
                .ThenInclude(u => u.StudentProfile)
            .Where(a => 
                (a.Student.StudentProfile.FullName != null && a.Student.StudentProfile.FullName.ToLower().Contains(lowerQuery)) ||
                (a.Student.StudentProfile.Skills != null && a.Student.StudentProfile.Skills.Any(s => s.ToLower().Contains(lowerQuery)))
            )
            .OrderByDescending(a => a.MatchScore)
            .ToListAsync();

        return applications.Select(a => new ApplicationResponseDto(
            a.AppId,
            a.Student?.StudentProfile?.FullName ?? "Unknown Candidate",
            a.Student?.StudentProfile?.UniversityName ?? "Unknown University",
            a.MatchScore,
            string.IsNullOrWhiteSpace(a.SummaryReport) ? Array.Empty<string>() : a.SummaryReport.Split('\n', StringSplitOptions.RemoveEmptyEntries),
            a.Student?.StudentProfile?.CvPdfUrl ?? "",
            a.Status.ToString(),
            a.InterviewDate,
            a.InterviewTime
        ));
    }

    /// <summary>
    /// UpdateApplicationStatusAsync
    /// Updates the status of a specific application. Parses the provided string into the ApplicationStatus enum,
    /// saves the changes to the database, and returns the updated application.
    /// </summary>
    public async Task<Application> UpdateApplicationStatusAsync(Guid appId, UpdateStatusRequestDto request)
    {
        var application = await _context.Applications.FindAsync(appId);
        
        if (application == null)
        {
            throw new KeyNotFoundException("Application not found");
        }

        if (!Enum.TryParse<ApplicationStatus>(request.NewStatus, true, out var nextStatus))
            throw new InvalidOperationException("Unknown application status.");
        if (nextStatus == ApplicationStatus.Admin_Approved && application.Status != ApplicationStatus.Agent_Evaluated)
            throw new InvalidOperationException("Only Agent_Evaluated applications can be approved by an administrator.");
        application.Status = nextStatus;
        
        await _context.SaveChangesAsync();
        
        return application;
    }

    /// <summary>
    /// ScheduleInterviewAsync
    /// Schedules an interview for a specific application by updating its InterviewDate and InterviewTime properties.
    /// Acts as a trigger point for invoking external AI agent scheduling logic.
    /// </summary>
    public async Task<Application> ScheduleInterviewAsync(Guid appId, ScheduleInterviewRequestDto request)
    {
        var application = await _context.Applications
            .Include(a => a.Student).ThenInclude(u => u.StudentProfile)
            .Include(a => a.Job)
            .FirstOrDefaultAsync(a => a.AppId == appId);
        
        if (application == null)
        {
            throw new KeyNotFoundException("Application not found");
        }

        if (application.Status != ApplicationStatus.Admin_Approved)
            throw new InvalidOperationException("Administrator approval is required before scheduling an interview.");

        application.InterviewDate = request.InterviewDate;
        application.InterviewTime = request.InterviewTime;
        application.Status = ApplicationStatus.Company_Scheduled;
        
        await _context.SaveChangesAsync();
        
        var interviewAt = request.InterviewDate.Date.Add(request.InterviewTime);
        await _emailService.SendInterviewScheduledAsync(
            application.Student.Email,
            application.Student.StudentProfile?.FullName ?? application.Student.Email,
            application.Job.JobTitle,
            interviewAt);
        
        return application;
    }



    /// <summary>
    /// GetCvDownloadUrlAsync
    /// Retrieves the CV download URL for a given application by fetching the associated student profile.
    /// Returns an empty string if no CV URL is found.
    /// </summary>
    public async Task<string> GetCvDownloadUrlAsync(Guid appId)
    {
        var application = await _context.Applications
            .Include(a => a.Student)
                .ThenInclude(u => u.StudentProfile)
            .FirstOrDefaultAsync(a => a.AppId == appId);

        if (application == null)
        {
            throw new KeyNotFoundException("Application not found");
        }

        return application.Student?.StudentProfile?.CvPdfUrl ?? string.Empty;
    }

    public async Task<Application> ApplyAsync(ApplyForJobDto request, CancellationToken cancellationToken = default)
    {
        var student = await _context.Users.FirstOrDefaultAsync(
            u => u.Id == request.StudentId && u.Role == UserRole.Student, cancellationToken);
        if (student is null) throw new KeyNotFoundException("Student not found.");
        if (student.Status != AccountStatus.Approved)
            throw new InvalidOperationException("Student account must be approved before applying.");
        if (!await _context.Jobs.AnyAsync(j => j.JobId == request.JobId, cancellationToken))
            throw new KeyNotFoundException("Job not found.");
        if (await _context.Applications.AnyAsync(a => a.StudentId == request.StudentId && a.JobId == request.JobId, cancellationToken))
            throw new InvalidOperationException("The student has already applied for this job.");

        var application = new Application
        {
            AppId = Guid.NewGuid(), StudentId = request.StudentId, JobId = request.JobId,
            Status = ApplicationStatus.Pending, SummaryReport = "{}"
        };
        _context.Applications.Add(application);
        await _context.SaveChangesAsync(cancellationToken);
        return application;
    }

    public async Task<object> EvaluateAsync(Guid appId, EvaluateApplicationDto request, CancellationToken cancellationToken = default)
    {
        var application = await _context.Applications
            .Include(a => a.Student).ThenInclude(u => u.StudentProfile)
            .FirstOrDefaultAsync(a => a.AppId == appId, cancellationToken)
            ?? throw new KeyNotFoundException("Application not found.");
        if (application.Status != ApplicationStatus.Pending)
            throw new InvalidOperationException($"Only Pending applications can be evaluated; current status is {application.Status}.");
        var cvKey = application.Student.StudentProfile?.CvPdfUrl;
        if (string.IsNullOrWhiteSpace(cvKey)) throw new InvalidOperationException("The student must upload a CV PDF before validation.");

        string? cvPdfBase64 = null;
        if (cvKey.StartsWith("local://") || cvKey.StartsWith("supabase://"))
        {
            var storedCv = await _documentStorage.OpenReadAsync(cvKey, cancellationToken)
                ?? throw new InvalidOperationException("The stored CV could not be read.");
            using var memory = new MemoryStream();
            await storedCv.Content.CopyToAsync(memory, cancellationToken);
            cvPdfBase64 = Convert.ToBase64String(memory.ToArray());
        }

        var body = JsonSerializer.Serialize(new
        {
            application_id = application.AppId,
            summary = request.Summary,
            cv_pdf_url = cvPdfBase64 is null ? cvKey : null,
            cv_pdf_base64 = cvPdfBase64
        });
        var aiBaseUrl = (_configuration["AiService:BaseUrl"] ?? "http://127.0.0.1:8000").TrimEnd('/');
        var response = await _httpClientFactory.CreateClient().PostAsync(
            $"{aiBaseUrl}/validate", new StringContent(body, Encoding.UTF8, "application/json"), cancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException($"Validation Agent failed: {await response.Content.ReadAsStringAsync(cancellationToken)}");

        application.SummaryReport = await response.Content.ReadAsStringAsync(cancellationToken);
        application.Status = ApplicationStatus.Agent_Evaluated;
        await _context.SaveChangesAsync(cancellationToken);
        return new
        {
            applicationId = application.AppId,
            status = application.Status.ToString(),
            requiresAdminApproval = true,
            validation = JsonSerializer.Deserialize<JsonElement>(application.SummaryReport)
        };
    }

    public async Task<IEnumerable<object>> GetPendingAdminApprovalAsync(CancellationToken cancellationToken = default)
    {
        var values = await _context.Applications
            .Where(a => a.Status == ApplicationStatus.Agent_Evaluated)
            .Include(a => a.Student).ThenInclude(u => u.StudentProfile)
            .Include(a => a.Job).ThenInclude(j => j.Company)
            .Select(a => new
            {
                applicationId = a.AppId,
                studentName = a.Student.StudentProfile != null ? a.Student.StudentProfile.FullName : a.Student.Email,
                jobTitle = a.Job.JobTitle,
                companyName = a.Job.Company.CompanyName,
                validationReport = a.SummaryReport,
                status = a.Status.ToString()
            }).ToListAsync(cancellationToken);
        return values.Cast<object>();
    }

    public async Task<Application> AdminDecisionAsync(Guid appId, bool approved, CancellationToken cancellationToken = default)
    {
        var application = await _context.Applications.FirstOrDefaultAsync(a => a.AppId == appId, cancellationToken)
            ?? throw new KeyNotFoundException("Application not found.");
        if (application.Status != ApplicationStatus.Agent_Evaluated)
            throw new InvalidOperationException("Application is not waiting for administrator approval.");
        application.Status = approved ? ApplicationStatus.Admin_Approved : ApplicationStatus.Rejected;
        await _context.SaveChangesAsync(cancellationToken);
        return application;
    }

    public async Task<IEnumerable<object>> GetStudentApplicationsAsync(Guid studentId, CancellationToken cancellationToken = default)
    {
        var values = await _context.Applications
            .Where(a => a.StudentId == studentId)
            .Include(a => a.Job).ThenInclude(j => j.Company)
            .Select(a => new
            {
                applicationId = a.AppId,
                jobTitle = a.Job.JobTitle,
                companyName = a.Job.Company.CompanyName,
                status = a.Status.ToString(),
                interviewDate = a.InterviewDate,
                interviewTime = a.InterviewTime,
                companyMessage = a.CompanyMessage
            }).ToListAsync(cancellationToken);
        return values.Cast<object>();
    }
}
