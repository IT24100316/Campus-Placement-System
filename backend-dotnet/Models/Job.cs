namespace backend_dotnet.Models;

public class Job
{
    public Guid JobId { get; set; } = Guid.NewGuid();
    public Guid CompanyId { get; set; }
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

    // Navigation properties
    public CompanyProfile Company { get; set; } = null!;
    public ICollection<Application> Applications { get; set; } = new List<Application>();
}
