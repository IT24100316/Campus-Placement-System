namespace backend_dotnet.Models;

public class TargetDomain
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }

    // Navigation properties
    public ICollection<JobTitleReference> JobTitles { get; set; } = new List<JobTitleReference>();
    public ICollection<Job> Jobs { get; set; } = new List<Job>();
}
