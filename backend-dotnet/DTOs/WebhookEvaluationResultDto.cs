using System;

namespace backend_dotnet.DTOs;

public class WebhookEvaluationResultDto
{
    public Guid ApplicationId { get; set; }
    public bool IsSuccess { get; set; }
    public string? ResultJson { get; set; }
}
