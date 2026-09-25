using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface IAuthService
{
    Task<AuthRegisterResultDto> RegisterAsync(RegisterRequestDto dto, CancellationToken cancellationToken = default);
    Task<AuthLoginResultDto?> LoginAsync(LoginDto dto);
    Task<AuthUserDto?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<AuthRegisterResultDto> RegisterCompanyHrAsync(RegisterCompanyHrDto dto);
    Task<AuthRegisterResultDto> RegisterCompanyStaffAsync(RegisterCompanyStaffDto dto);
    Task<AuthRegisterResultDto> RegisterStudentAsync(RegisterStudentFormDto dto, CancellationToken cancellationToken = default);
    Task<IEnumerable<ApprovedCompanyDto>> GetCompaniesAsync();
}
