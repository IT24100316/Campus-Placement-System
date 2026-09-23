using System;

namespace backend_dotnet.DTOs;

public class AuthLoginResultDto
{
    public Guid UserId { get; set; }
    public bool Success { get; set; }
    public bool IsPending { get; set; }
    public bool IsRejected { get; set; }
    public string Message { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Role { get; set; }
    public string? Status { get; set; }
    public string? CompanyName { get; set; }
    public string? FullName { get; set; }
    public string? StaffId { get; set; }
    public string? JobPosition { get; set; }
}

public class AuthRegisterResultDto
{
    public bool Success { get; set; } = true;
    public string Message { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string? CompanyName { get; set; }
    public string? Status { get; set; }
}
