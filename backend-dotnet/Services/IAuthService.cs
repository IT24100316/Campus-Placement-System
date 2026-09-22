using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface IAuthService
{
    Task<AuthLoginResultDto?> LoginAsync(LoginDto dto);
    Task<AuthRegisterResultDto> RegisterCompanyHrAsync(RegisterCompanyHrDto dto);
    Task<AuthRegisterResultDto> RegisterCompanyStaffAsync(RegisterCompanyStaffDto dto);
    Task<IEnumerable<ApprovedCompanyDto>> GetCompaniesAsync();
}
