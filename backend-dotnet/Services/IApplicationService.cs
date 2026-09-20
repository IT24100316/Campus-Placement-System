using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.Models;

namespace backend_dotnet.Services;

public interface IApplicationService
{
    Task<IEnumerable<Application>> GetApplicationsByJobIdAsync(Guid jobId, int page, string status);
    Task<IEnumerable<Application>> SearchApplicationsAsync(string query);
    Task<Application> UpdateApplicationStatusAsync(Guid appId, string newStatus);
    Task<Application> ScheduleInterviewAsync(Guid appId, DateTime date, TimeSpan time);
    Task<string> GetCvDownloadUrlAsync(Guid appId);
}
