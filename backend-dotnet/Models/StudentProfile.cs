namespace backend_dotnet.Models;

public class StudentProfile
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

    // Navigation property
    public User User { get; set; } = null!;
}
