namespace backend_dotnet.Models;

public class CompanyProfile
{
    public Guid UserId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string Industry { get; set; } = string.Empty;
    public string ContactPersonEmail { get; set; } = string.Empty;
    public string BusinessRegistrationDocumentUrl { get; set; } = string.Empty;

    // Navigation properties
    public User User { get; set; } = null!;
    public ICollection<Job> Jobs { get; set; } = new List<Job>();
}
