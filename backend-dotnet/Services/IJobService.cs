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
    Task<PaginatedResult<JobFeedDto>> GetJobFeedAsync(string? search, string? skills, string? domain, string[]? workArrangements, bool? isPaidOnly, bool? isEligible, System.Guid? studentUserId, decimal? minGpa, decimal? maxGpa, int[]? allowedYears, string? sortBy, int page, int pageSize);
    Task<JobDetailsDto?> GetJobDetailsAsync(System.Guid jobId);
}
