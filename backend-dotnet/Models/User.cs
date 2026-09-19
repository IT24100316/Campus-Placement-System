namespace backend_dotnet.Models;

public enum UserRole
{
    Student,
    Company,
    Admin
}

public class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Role { get; set; }

    // Navigation properties
    public StudentProfile? StudentProfile { get; set; }
    public ICollection<Job> PostedJobs { get; set; } = new List<Job>();
    public ICollection<Application> Applications { get; set; } = new List<Application>();
}
