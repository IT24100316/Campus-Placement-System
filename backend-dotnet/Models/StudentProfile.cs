namespace backend_dotnet.Models;

public class StudentProfile
{
    public Guid StudentId { get; set; }
    public string[] Skills { get; set; } = Array.Empty<string>();
    public string[] Languages { get; set; } = Array.Empty<string>();
    public string Degree { get; set; } = string.Empty;
    public decimal GPA { get; set; }
    public int Year { get; set; }
    public string CV_Url { get; set; } = string.Empty;

    // Navigation property
    public User Student { get; set; } = null!;
}
