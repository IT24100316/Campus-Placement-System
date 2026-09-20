using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.Models;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface IApplicationService
{
    Task<IEnumerable<ApplicationResponseDto>> GetApplicationsByJobIdAsync(Guid jobId, int page, string status);
    Task<IEnumerable<ApplicationResponseDto>> SearchApplicationsAsync(string query);
    Task<Application> UpdateApplicationStatusAsync(Guid appId, UpdateStatusRequestDto request);
    Task<Application> ScheduleInterviewAsync(Guid appId, ScheduleInterviewRequestDto request);
    Task<string> GetCvDownloadUrlAsync(Guid appId);
}
