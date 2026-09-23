namespace backend_dotnet.Models;

public class SkillEquivalence
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string TermA { get; set; } = string.Empty;
    public string TermB { get; set; } = string.Empty;
    public bool IsMatch { get; set; }
    public string? Reason { get; set; }
    public string Source { get; set; } = "llm";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
