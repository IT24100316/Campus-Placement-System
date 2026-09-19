namespace backend_dotnet.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public AccountStatus Status { get; set; } = AccountStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public StudentProfile? StudentProfile { get; set; }
    public CompanyProfile? CompanyProfile { get; set; }
    public ICollection<Application> Applications { get; set; } = new List<Application>();
}
