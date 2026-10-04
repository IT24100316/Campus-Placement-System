namespace backend_dotnet.DTOs;

public class StudentProfileUpsertRequest
{
    // Draft requests intentionally accept partial values. The controller
    // applies the full internship-registration requirements when IsDraft is false.
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public string? CampusIdPhotoUrl { get; set; }
    public string? PortfolioUrl { get; set; }
    public string? UniversityName { get; set; }
    public string? AcademicStatus { get; set; }
    public string? DegreeProgram { get; set; }
    public int? CurrentYearOfStudy { get; set; }
    public decimal? GPA { get; set; }
    public DateTime? ExpectedGraduationDate { get; set; }
    public string? DesiredJobTitle { get; set; }
    public string? PrimaryDomain { get; set; }
    public string? CareerObjectivesSummary { get; set; }
    public string[]? Skills { get; set; }
    public string[]? ToolsAndTechnologies { get; set; }
    public string[]? InternshipType { get; set; }
    public string? LectureScheduleType { get; set; }
    public string[]? PreferredLocations { get; set; }
    public bool IsDraft { get; set; }
}

public class StudentProfileResponse
{
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string CampusIdPhotoUrl { get; set; } = string.Empty;
    public string? PortfolioUrl { get; set; }
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
    public string LectureScheduleType { get; set; } = string.Empty;
    public string[] PreferredLocations { get; set; } = Array.Empty<string>();
    public string CvPdfUrl { get; set; } = string.Empty;
    public DateTime? CvUploadedAt { get; set; }
    public DateTime? CvNextEligibleUploadAt { get; set; }
}
