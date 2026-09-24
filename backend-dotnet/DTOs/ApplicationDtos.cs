using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace backend_dotnet.DTOs;

public sealed class StudentApplicationSubmissionRequestDto : IValidatableObject
{
    [Required]
    public Guid? JobId { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (JobId == Guid.Empty)
        {
            yield return new ValidationResult(
                "A valid job ID is required.",
                new[] { nameof(JobId) });
        }
    }
}

public sealed record StudentApplicationSubmissionResponseDto(
    Guid AppId,
    Guid JobId,
    string Status
);

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
