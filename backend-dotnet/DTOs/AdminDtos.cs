namespace backend_dotnet.DTOs;

public class AdminApprovalResponseDto
{
    public bool Success { get; set; } = true;
    public string Message { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool EmailSent { get; set; }
}

public class AdminRegisterEmployeeResponseDto
{
    public bool Success { get; set; } = true;
    public string Message { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public Guid CompanyId { get; set; }
    public string StaffId { get; set; } = string.Empty;
    public string JobPosition { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
