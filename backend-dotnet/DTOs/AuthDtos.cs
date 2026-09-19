using System.ComponentModel.DataAnnotations;

namespace backend_dotnet.DTOs;

public class RegisterCompanyHrDto
{
    [Required]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = string.Empty;

    [Required]
    public string Phone { get; set; } = string.Empty;

    [Required]
    public string CompanyName { get; set; } = string.Empty;

    [Required]
    public string Industry { get; set; } = string.Empty;

    public string BusinessRegistrationDocumentUrl { get; set; } = string.Empty;
}

public class RegisterCompanyStaffDto
{
    [Required]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = string.Empty;

    public string? Phone { get; set; }

    [Required]
    public Guid CompanyId { get; set; }

    [Required]
    public string StaffId { get; set; } = string.Empty;

    [Required]
    public string JobPosition { get; set; } = string.Empty;
}

public class ApprovedCompanyDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Industry { get; set; } = string.Empty;
}

public class PendingUserDto
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public string? Industry { get; set; }
    public string? Phone { get; set; }
    public string? StaffId { get; set; }
    public string? JobPosition { get; set; }
    public string? BusinessRegistrationDocumentUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}
