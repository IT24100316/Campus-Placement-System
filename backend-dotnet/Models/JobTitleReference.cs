namespace backend_dotnet.Models;

public class JobTitleReference
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int TargetDomainId { get; set; }

    // Navigation properties
    public TargetDomain TargetDomain { get; set; } = null!;
    public ICollection<Job> Jobs { get; set; } = new List<Job>();
}
