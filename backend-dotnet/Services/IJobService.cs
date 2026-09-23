using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface IJobService
{
    Task<IEnumerable<TargetDomainDto>> GetTargetDomainsAsync();
    Task<IEnumerable<JobTitleDto>> GetJobTitlesAsync(int? domainId, string? domain);
    IEnumerable<string> GetInternshipTypes();
    Task<JobCreationResultDto> CreateJobAsync(CreateJobRequestDto request);
}
