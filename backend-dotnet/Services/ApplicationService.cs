using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
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
    private readonly INotificationService? _notificationService;

    public ApplicationService(
        AppDbContext context,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        IEmailService emailService,
        IDocumentStorageService documentStorage,
        INotificationService? notificationService = null)
    {
        _context = context;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _emailService = emailService;
        _documentStorage = documentStorage;
        _notificationService = notificationService;
    }

    // Fetches all the applications for a specific job, and grabs the candidate details too.
    // It also allows filtering by application status, and returns a paginated list so it doesn't load everything at once!
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


    // Searches through all applications by checking if the student's name or their skills match the search text.
    public async Task<IEnumerable<ApplicationResponseDto>> SearchApplicationsAsync(string query)
    {
        var lowerQuery = string.IsNullOrWhiteSpace(query) ? string.Empty : query.ToLower();

        var applications = await _context.Applications
            .Include(a => a.Student)
                .ThenInclude(u => u.StudentProfile)
            .Where(a => 
                (a.Student.StudentProfile != null && a.Student.StudentProfile.FullName != null && a.Student.StudentProfile.FullName.ToLower().Contains(lowerQuery)) ||
                (a.Student.StudentProfile != null && a.Student.StudentProfile.Skills != null && a.Student.StudentProfile.Skills.Any(s => s.ToLower().Contains(lowerQuery)))
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



    // Finds the application and grabs the link to download the student's CV.
    // If it can't find one, it just returns an empty string.
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

    // Handles the process when a student clicks "Apply" for a job.
    // We double-check if their account is approved, make sure the job actually exists, and verify they haven't applied already!
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
        _notificationService?.Add(
            application.StudentId,
            "application_received",
            "Application received",
            "Your application has been submitted and is awaiting review.",
            "applications",
            application.AppId);
        await _context.SaveChangesAsync(cancellationToken);
        return application;
    }

    // Receives the results back from our AI Evaluation Engine.
    // It updates the application with the AI's match score and feedback, or marks it as failed if something went wrong during the AI check.
    public async Task HandleEvaluationWebhookAsync(WebhookEvaluationResultDto payload, CancellationToken cancellationToken = default)
    {
        // Look up by ApplicationId OR by JobId + StudentId
        var application = await _context.Applications
            .FirstOrDefaultAsync(a => a.AppId == payload.ApplicationId 
                                   || (a.JobId == payload.JobId && a.StudentId == payload.StudentId), cancellationToken);
                                   
        if (application == null)
        {
            // Auto-Match on Publish Flow: Create a new application!
            application = new Application
            {
                AppId = Guid.NewGuid(),
                StudentId = payload.StudentId,
                JobId = payload.JobId,
                Status = ApplicationStatus.Processing, // Briefly processing before updated below
                SummaryReport = "{}"
            };
            _context.Applications.Add(application);
        }
        
        // At this point we bypass the strict "Processing" check because it might be a fresh auto-match
        // or a re-run. We just update it.

        if (payload.IsSuccess)
        {
            application.SummaryReport = payload.ResultJson ?? "{}";
            application.MatchScore = payload.MatchScore;
            application.Status = ApplicationStatus.Agent_Evaluated;
            _notificationService?.Add(
                application.StudentId,
                "application_update",
                "Application update",
                "Your application has completed the initial review.",
                "applications",
                application.AppId);
        }
        else
        {
            application.SummaryReport = payload.ResultJson ?? "{\"error\": \"Unknown evaluation error\"}";
            application.Status = ApplicationStatus.Evaluation_Failed;
        }

        await _context.SaveChangesAsync(cancellationToken);
    }

    // Grabs a list of all applications that are waiting for the university admin to review and approve them.
    public async Task<IEnumerable<object>> GetPendingAdminApprovalAsync(CancellationToken cancellationToken = default)
    {
        var values = await _context.Applications
            .Where(a => a.Status != ApplicationStatus.Pending && a.Status != ApplicationStatus.Processing)
            .Include(a => a.Student).ThenInclude(u => u.StudentProfile)
            .Include(a => a.Job).ThenInclude(j => j.Company)
            .Select(a => new
            {
                applicationId = a.AppId,
                studentName = a.Student.StudentProfile != null ? a.Student.StudentProfile.FullName : a.Student.Email,
                jobTitle = a.Job.JobTitle,
                jobDescription = a.Job.JobDescriptionSummary,
                jobDuration = a.Job.DurationMonths,
                jobStipend = a.Job.StipendOffered,
                jobMinGPA = a.Job.MinimumGPA,
                mandatorySkills = a.Job.MandatorySkills,
                niceToHaveSkills = a.Job.NiceToHaveSkills,
                preferredDegrees = a.Job.PreferredDegreePrograms,
                allowedYears = a.Job.AllowedYearsOfStudy,
                companyName = a.Job.Company.CompanyName,
                validationReport = a.SummaryReport,
                matchScore = a.MatchScore,
                status = a.Status.ToString(),
                university = a.Student.StudentProfile != null ? a.Student.StudentProfile.UniversityName : "Unknown",
                gpa = a.Student.StudentProfile != null ? a.Student.StudentProfile.GPA : 0,
                skills = a.Student.StudentProfile != null ? a.Student.StudentProfile.Skills : null,
                cvUrl = a.Student.StudentProfile != null ? a.Student.StudentProfile.CvPdfUrl : string.Empty,
                phone = a.Student.StudentProfile != null ? a.Student.StudentProfile.Phone : string.Empty,
                portfolioUrl = a.Student.StudentProfile != null ? a.Student.StudentProfile.PortfolioUrl : string.Empty,
                tools = a.Student.StudentProfile != null ? a.Student.StudentProfile.ToolsAndTechnologies : null,
                internshipType = a.Student.StudentProfile != null ? a.Student.StudentProfile.InternshipType : null,
                preferredLocations = a.Student.StudentProfile != null ? a.Student.StudentProfile.PreferredLocations : null,
                lectureSchedule = a.Student.StudentProfile != null ? a.Student.StudentProfile.LectureScheduleType : string.Empty,
                degreeProgram = a.Student.StudentProfile != null ? a.Student.StudentProfile.DegreeProgram : string.Empty,
                academicStatus = a.Student.StudentProfile != null ? a.Student.StudentProfile.AcademicStatus : string.Empty,
                careerObjectives = a.Student.StudentProfile != null ? a.Student.StudentProfile.CareerObjectivesSummary : string.Empty,
                graduationYear = (a.Student.StudentProfile != null && a.Student.StudentProfile.ExpectedGraduationDate.HasValue) ? a.Student.StudentProfile.ExpectedGraduationDate.Value.Year.ToString() : "N/A"
            }).ToListAsync(cancellationToken);
        return values.Cast<object>();
    }

    // Processes the university admin's decision (approve or reject) for an application.
    // If the admin approves it, the student is given 3 days to make their final decision!
    public async Task<Application> AdminDecisionAsync(Guid appId, bool approved, CancellationToken cancellationToken = default)
    {
        var application = await _context.Applications.FirstOrDefaultAsync(a => a.AppId == appId, cancellationToken)
            ?? throw new KeyNotFoundException("Application not found.");
        if (application.Status != ApplicationStatus.Agent_Evaluated)
            throw new InvalidOperationException("Application is not waiting for administrator approval.");
        application.Status = approved ? ApplicationStatus.Admin_Approved : ApplicationStatus.Rejected;
        if (approved) {
            application.DecisionDeadline = DateTime.UtcNow.AddDays(3);
        }
        _notificationService?.Add(
            application.StudentId,
            approved ? "action_required" : "application_update",
            approved ? "Action required: respond to your offer" : "Application update",
            approved
                ? "You have been shortlisted. Review and respond to the offer within three days."
                : "Your application was not selected on this occasion.",
            "applications",
            application.AppId);
        await _context.SaveChangesAsync(cancellationToken);
        return application;
    }

    // Processes the student's final decision to either accept or reject the university-approved application.
    public async Task<Application> StudentDecisionAsync(Guid appId, Guid studentId, bool accepted, CancellationToken cancellationToken = default)
    {
        var application = await _context.Applications.FirstOrDefaultAsync(a => a.AppId == appId && a.StudentId == studentId, cancellationToken)
            ?? throw new KeyNotFoundException("Application not found or access denied.");
        if (application.Status != ApplicationStatus.Admin_Approved)
            throw new InvalidOperationException("Application is not in a valid state for a student decision.");
        application.Status = accepted ? ApplicationStatus.Student_Accepted : ApplicationStatus.Rejected;
        await _context.SaveChangesAsync(cancellationToken);
        return application;
    }

    // Gets all the applications a specific student has made so they can view their status on their dashboard.
    public async Task<IEnumerable<object>> GetStudentApplicationsAsync(Guid studentId, CancellationToken cancellationToken = default)
    {
        var values = await _context.Applications
            .Where(a => a.StudentId == studentId)
            .Include(a => a.Job).ThenInclude(j => j.Company)
            .Select(a => new
            {
                applicationId = a.AppId,
                jobId = a.JobId,
                jobTitle = a.Job.JobTitle,
                companyName = a.Job.Company.CompanyName,
                status = a.Status.ToString(),
                interviewDate = a.InterviewDate,
                interviewTime = a.InterviewTime,
                companyMessage = a.CompanyMessage,
                decisionDeadline = a.DecisionDeadline
            }).ToListAsync(cancellationToken);
        return values.Cast<object>();
    }

    // Books an interview for the student!
    // It sets the date and time, emails the student with a calendar invite, and updates the application status to show they're scheduled.
    public async Task<bool> ScheduleInterviewAsync(ScheduleInterviewRequestDto request)
    {
        // 1. Strict Validation: Verify Application exists for this specific Student and Job relationship
        var application = await _context.Applications
            .Include(a => a.Student)
                .ThenInclude(u => u.StudentProfile)
            .Include(a => a.Job)
                .ThenInclude(j => j.Company)
            .FirstOrDefaultAsync(a => a.StudentId == request.StudentId && a.JobId == request.JobId);

        if (application == null || application.Status != ApplicationStatus.Student_Accepted)
        {
            return false;
        }

        // 2. Extract Data Securely (Do not trust frontend for these fields)
        var studentEmail = application.Student.Email;
        var studentName = application.Student.StudentProfile?.FullName ?? "Student";
        var companyName = application.Job.Company?.CompanyName ?? "Company";
        var jobTitle = application.Job.JobTitle;

        // 3. Set the confirmed interview dates in the entity (Not saved yet)
        application.InterviewDate = DateTime.SpecifyKind(request.InterviewDate, DateTimeKind.Utc);
        application.InterviewTime = request.InterviewTime;
        
        // 4. Generate .ics and Dispatch Email via SendGrid Service (with Polly resilience built-in)
        var emailSent = await _emailService.SendInterviewScheduledAsync(
            studentEmail,
            studentName,
            companyName,
            jobTitle,
            request.InterviewDate,
            request.InterviewTime,
            request.MeetingLink
        );

        if (!emailSent)
        {
            return false;
        }

        // 5. Database Consistency: Only save state to DB if the third-party SendGrid request succeeded
        application.InterviewStatus = InterviewStatus.Invited;
        application.Status = ApplicationStatus.Company_Scheduled;
        _notificationService?.Add(
            application.StudentId,
            "interview",
            "Interview scheduled",
            $"Your interview for {jobTitle} has been scheduled.",
            "applications",
            application.AppId);

        await _context.SaveChangesAsync();

        return true;
    }

    // Marks a candidate as rejected by the company, and optionally emails them the reason so they know what happened.
    public async Task<bool> RejectCandidateAsync(RejectCandidateRequestDto request)
    {
        var application = await _context.Applications
            .Include(a => a.Student)
                .ThenInclude(u => u.StudentProfile)
            .Include(a => a.Job)
                .ThenInclude(j => j.Company)
            .FirstOrDefaultAsync(a => a.StudentId == request.StudentId && a.JobId == request.JobId);

        if (application == null)
        {
            return false;
        }

        var studentEmail = application.Student.Email;
        var studentName = application.Student.StudentProfile?.FullName ?? "Student";
        var companyName = application.Job.Company?.CompanyName ?? "Company";
        var jobTitle = application.Job.JobTitle;

        // Optionally send a rejection email
        await _emailService.SendCandidateRejectedAsync(
            studentEmail,
            studentName,
            companyName,
            jobTitle,
            request.Reason
        );

        application.Status = ApplicationStatus.Rejected;
        application.CompanyMessage = request.Reason; // Save reason in CompanyMessage or just leave it for now.
        _notificationService?.Add(
            application.StudentId,
            "application_update",
            "Application update",
            $"Your application for {jobTitle} was not selected.",
            "applications",
            application.AppId);

        await _context.SaveChangesAsync();
        return true;
    }
}
