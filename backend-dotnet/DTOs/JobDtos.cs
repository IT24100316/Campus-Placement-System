using System.ComponentModel.DataAnnotations;
using backend_dotnet.Models;

namespace backend_dotnet.DTOs;

public class TargetDomainDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int TitleCount { get; set; }
}

public class JobTitleDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int TargetDomainId { get; set; }
    public string TargetDomainName { get; set; } = string.Empty;
}

public class CreateJobRequestDto
{
    public Guid? CompanyId { get; set; }
    public string? RecruiterEmail { get; set; }

    [Required(ErrorMessage = "Target Domain is required.")]
    public string TargetDomain { get; set; } = string.Empty;
    public int? TargetDomainId { get; set; }

    [Required(ErrorMessage = "Job Title is required.")]
    public string JobTitle { get; set; } = string.Empty;
    public int? JobTitleId { get; set; }

    [Required(ErrorMessage = "Job Description Summary is required.")]
    [StringLength(3000, MinimumLength = 10, ErrorMessage = "Job description summary must be between 10 and 3000 characters.")]
    public string JobDescriptionSummary { get; set; } = string.Empty;

    [Required(ErrorMessage = "Internship Type is required.")]
    public string InternshipType { get; set; } = string.Empty; // "OnSite", "Hybrid", "Remote"

    [Required(ErrorMessage = "Location city is required.")]
    public string LocationCity { get; set; } = string.Empty;

    [Range(0.00, 4.00, ErrorMessage = "Minimum GPA must be between 0.00 and 4.00.")]
    public decimal MinimumGPA { get; set; } = 3.00m;

    public int[] AllowedYearsOfStudy { get; set; } = Array.Empty<int>();

    public string[] MandatorySkills { get; set; } = Array.Empty<string>();

    public string[] NiceToHaveSkills { get; set; } = Array.Empty<string>();

    public string[] PreferredDegreePrograms { get; set; } = Array.Empty<string>();

    public bool StipendOffered { get; set; } = false;

    public string? StipendAmountOrDetails { get; set; }

    [Range(1, 24, ErrorMessage = "Duration must be between 1 and 24 months.")]
    public int DurationMonths { get; set; } = 6;

    [Required(ErrorMessage = "Application deadline is required.")]
    public DateTime ApplicationDeadline { get; set; }
}

public class JobResponseDto
{
    public Guid JobId { get; set; }
    public Guid CompanyId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string JobTitle { get; set; } = string.Empty;
    public string TargetDomain { get; set; } = string.Empty;
    public string JobDescriptionSummary { get; set; } = string.Empty;
    public string[] InternshipType { get; set; } = Array.Empty<string>();
    public string LocationCity { get; set; } = string.Empty;
    public decimal MinimumGPA { get; set; }
    public int[] AllowedYearsOfStudy { get; set; } = Array.Empty<int>();
    public string[] MandatorySkills { get; set; } = Array.Empty<string>();
    public string[] NiceToHaveSkills { get; set; } = Array.Empty<string>();
    public string[] PreferredDegreePrograms { get; set; } = Array.Empty<string>();
    public bool StipendOffered { get; set; }
    public string? StipendAmountOrDetails { get; set; }
    public int DurationMonths { get; set; }
    public DateTime ApplicationDeadline { get; set; }
    public int MatchesVerified { get; set; }
    public string Status { get; set; } = "Active • Accepting";
}
