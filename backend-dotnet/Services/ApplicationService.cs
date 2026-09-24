using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Npgsql;

namespace backend_dotnet.Services;

public class ApplicationService : IApplicationService
{
    private readonly AppDbContext _context;

    public ApplicationService(AppDbContext context)
    {
        _context = context;
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

        application.Status = Enum.Parse<ApplicationStatus>(request.NewStatus, true);
        
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
        var application = await _context.Applications.FindAsync(appId);
        
        if (application == null)
        {
            throw new KeyNotFoundException("Application not found");
        }

        application.InterviewDate = request.InterviewDate;
        application.InterviewTime = request.InterviewTime;
        
        await _context.SaveChangesAsync();
        
        // TODO: Construct Agent4InterviewPayload DTO and call Python Agent 4 (FastAPI) here.
        
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
}
