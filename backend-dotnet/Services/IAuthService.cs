using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface IAuthService
{
    Task<AuthLoginResultDto?> LoginAsync(LoginDto dto);
    Task<AuthRegisterResultDto> RegisterCompanyHrAsync(RegisterCompanyHrDto dto);
    Task<AuthRegisterResultDto> RegisterCompanyStaffAsync(RegisterCompanyStaffDto dto);
    Task<AuthRegisterResultDto> RegisterStudentAsync(RegisterStudentFormDto dto, CancellationToken cancellationToken = default);
    Task<IEnumerable<ApprovedCompanyDto>> GetCompaniesAsync();
}
