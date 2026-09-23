using System;

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
