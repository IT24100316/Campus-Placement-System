namespace backend_dotnet.Models;

public class Job
{
    public Guid JobId { get; set; }
    public Guid CompanyId { get; set; }
    public string JobTitle { get; set; } = string.Empty;
    public string[] Req_Skills { get; set; } = Array.Empty<string>();
    public string[] Req_Languages { get; set; } = Array.Empty<string>();
    public string Req_Degree { get; set; } = string.Empty;
    public decimal Min_GPA { get; set; }
    public int Target_Year { get; set; }

    // Navigation properties
    public User Company { get; set; } = null!;
    public ICollection<Application> Applications { get; set; } = new List<Application>();
}
