using System;
using System.Threading.Tasks;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface ICompanyService
{
    Task<CompanyDashboardResponseDto?> GetCompanyDashboardAsync(string? email, Guid? companyId);
    Task<bool> DeleteJobAsync(Guid jobId);
}
