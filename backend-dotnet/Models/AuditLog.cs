namespace backend_dotnet.Models;

public class AuditLog
{
    public Guid LogId { get; set; }
    public string Action { get; set; } = string.Empty;
    public Guid PerformedBy { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // Navigation property (Optional/Recommended)
    public User Performer { get; set; } = null!;
}
