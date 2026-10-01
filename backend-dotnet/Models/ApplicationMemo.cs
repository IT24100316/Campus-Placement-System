namespace backend_dotnet.Models;

public class ApplicationMemo
{
    public Guid MemoId { get; set; } = Guid.NewGuid();
    public Guid ApplicationId { get; set; }
    public Guid StaffId { get; set; }
    public string MemoText { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending"; // 'Pending' or 'Resolved'
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Application Application { get; set; } = null!;
    public User Staff { get; set; } = null!;
}
