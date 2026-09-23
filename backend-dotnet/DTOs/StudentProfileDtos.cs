using System.ComponentModel.DataAnnotations;

namespace backend_dotnet.DTOs;

public class StudentProfileUpsertRequest
{
    [Required, StringLength(255)]
    public string FullName { get; set; } = string.Empty;

    [Required, RegularExpression(@"^\+?[0-9][0-9\s\-()]{6,24}$")]
    public string Phone { get; set; } = string.Empty;

    [StringLength(2048)]
    public string CampusIdPhotoUrl { get; set; } = string.Empty;

    [Required, StringLength(255)]
    public string UniversityName { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string AcademicStatus { get; set; } = string.Empty;

    [Required, StringLength(255)]
    public string DegreeProgram { get; set; } = string.Empty;

    [Range(1, 8)]
    public int CurrentYearOfStudy { get; set; }

    [Range(typeof(decimal), "0", "4.00")]
    public decimal GPA { get; set; }

    [Required, FutureOrToday]
    public DateTime? ExpectedGraduationDate { get; set; }

    [Required, StringLength(255)]
    public string DesiredJobTitle { get; set; } = string.Empty;

    [Required, StringLength(150)]
    public string PrimaryDomain { get; set; } = string.Empty;

    [Required, StringLength(1000)]
    public string CareerObjectivesSummary { get; set; } = string.Empty;

    [MinLength(1)]
    public string[] Skills { get; set; } = Array.Empty<string>();

    [MinLength(1)]
    public string[] ToolsAndTechnologies { get; set; } = Array.Empty<string>();

    [MinLength(1)]
    public string[] InternshipType { get; set; } = Array.Empty<string>();

    [MinLength(1)]
    public string[] PreferredLocations { get; set; } = Array.Empty<string>();

    [StringLength(2048)]
    public string CvPdfUrl { get; set; } = string.Empty;
}

public sealed class FutureOrTodayAttribute : ValidationAttribute
{
    public FutureOrTodayAttribute()
        : base("The expected graduation date must be today or later.")
    {
    }

    public override bool IsValid(object? value)
    {
        return value is DateTime date && date.Date >= DateTime.UtcNow.Date;
    }
}

public class StudentProfileResponse
{
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string CampusIdPhotoUrl { get; set; } = string.Empty;
    public string UniversityName { get; set; } = string.Empty;
    public string AcademicStatus { get; set; } = string.Empty;
    public string DegreeProgram { get; set; } = string.Empty;
    public int CurrentYearOfStudy { get; set; }
    public decimal GPA { get; set; }
    public DateTime? ExpectedGraduationDate { get; set; }
    public string DesiredJobTitle { get; set; } = string.Empty;
    public string PrimaryDomain { get; set; } = string.Empty;
    public string CareerObjectivesSummary { get; set; } = string.Empty;
    public string[] Skills { get; set; } = Array.Empty<string>();
    public string[] ToolsAndTechnologies { get; set; } = Array.Empty<string>();
    public string[] InternshipType { get; set; } = Array.Empty<string>();
    public string[] PreferredLocations { get; set; } = Array.Empty<string>();
    public string CvPdfUrl { get; set; } = string.Empty;
}
