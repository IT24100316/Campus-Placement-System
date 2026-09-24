using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.Models;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface IApplicationService
{
    Task<StudentApplicationSubmissionResponseDto> SubmitStudentApplicationAsync(
        Guid studentId, Guid jobId, CancellationToken cancellationToken);
    Task<IEnumerable<ApplicationResponseDto>> GetApplicationsByJobIdAsync(Guid jobId, int page, string status);
    Task<IEnumerable<ApplicationResponseDto>> SearchApplicationsAsync(string query);
    Task<Application> UpdateApplicationStatusAsync(Guid appId, UpdateStatusRequestDto request);
    Task<Application> ScheduleInterviewAsync(Guid appId, ScheduleInterviewRequestDto request);
    Task<string> GetCvDownloadUrlAsync(Guid appId);
    Task<Application> ApplyAsync(ApplyForJobDto request, CancellationToken cancellationToken = default);
    Task<object> EvaluateAsync(Guid appId, EvaluateApplicationDto request, CancellationToken cancellationToken = default);
    Task<IEnumerable<object>> GetPendingAdminApprovalAsync(CancellationToken cancellationToken = default);
    Task<Application> AdminDecisionAsync(Guid appId, bool approved, CancellationToken cancellationToken = default);
    Task<IEnumerable<object>> GetStudentApplicationsAsync(Guid studentId, CancellationToken cancellationToken = default);
}
