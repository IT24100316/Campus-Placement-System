using System;
using System.ComponentModel.DataAnnotations;

namespace backend_dotnet.DTOs;

public record ApplicationResponseDto(
    Guid AppId,
    string CandidateName,
    string University,
    int MatchScore,
    string[] AiSummaryPoints,
    string CvUrl,
    string Status,
    DateTime? InterviewDate,
    TimeSpan? InterviewTime
);

public class ScheduleInterviewRequestDto
{
    public Guid StudentId { get; set; }
    public Guid JobId { get; set; }
    public DateTime InterviewDate { get; set; }
    public TimeSpan InterviewTime { get; set; }
    public string? MeetingLink { get; set; }
}

public record UpdateStatusRequestDto(
    string NewStatus
);

public class ApplyForJobDto
{
    public Guid StudentId { get; set; }
    public Guid JobId { get; set; }
}

public class EvaluateApplicationDto
{
    [Required]
    public string Summary { get; set; } = string.Empty;
}
