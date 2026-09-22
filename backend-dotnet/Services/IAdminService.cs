using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using backend_dotnet.DTOs;

namespace backend_dotnet.Services;

public interface IAdminService
{
    Task<IEnumerable<PendingUserDto>> GetPendingApprovalsAsync();
    Task<AdminApprovalResponseDto?> ApproveUserAsync(string identifier);
    Task<AdminApprovalResponseDto?> RejectUserAsync(string identifier);
    Task<AdminRegisterEmployeeResponseDto> RegisterEmployeeAsync(AdminRegisterEmployeeDto dto);
}
