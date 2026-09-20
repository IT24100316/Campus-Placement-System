using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;

namespace backend_dotnet.Services;

public class ApplicationService : IApplicationService
{
    private readonly AppDbContext _context;

    public ApplicationService(AppDbContext context)
    {
        _context = context;
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
