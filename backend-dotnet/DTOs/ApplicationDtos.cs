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

public record ScheduleInterviewRequestDto(
    DateTime InterviewDate,
    TimeSpan InterviewTime
);

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
