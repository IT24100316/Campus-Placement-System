namespace backend_dotnet.Models;

public class CompanyStaffProfile
{
    public Guid UserId { get; set; }
    public Guid CompanyId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string StaffId { get; set; } = string.Empty;
    public string JobPosition { get; set; } = string.Empty;

    // Navigation properties
    public User User { get; set; } = null!;
    public CompanyProfile Company { get; set; } = null!;
}
