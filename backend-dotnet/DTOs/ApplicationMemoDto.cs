namespace backend_dotnet.DTOs;

public class CreateMemoDto
{
    public Guid ApplicationId { get; set; }
    public string MemoText { get; set; } = string.Empty;
}

public class UpdateMemoDto
{
    public string MemoText { get; set; } = string.Empty;
}

public class MemoResponseDto
{
    public Guid MemoId { get; set; }
    public Guid ApplicationId { get; set; }
    public Guid StaffId { get; set; }
    public string StaffName { get; set; } = string.Empty;
    public string MemoText { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
