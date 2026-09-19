namespace backend_dotnet.Models;

public class Application
{
    public Guid AppId { get; set; }
    public Guid StudentId { get; set; }
    public Guid JobId { get; set; }
    public int MatchScore { get; set; }
    public string SummaryReport { get; set; } = string.Empty; // Column type 'jsonb'
    public string Status { get; set; } = "Pending"; // Pending, Admin_Approved, Student_Accepted, Company_Scheduled
    public DateTime? InterviewDate { get; set; }
    public TimeSpan? InterviewTime { get; set; }
    public string? CompanyMessage { get; set; }

    // Navigation properties
    public User Student { get; set; } = null!;
    public Job Job { get; set; } = null!;
}
