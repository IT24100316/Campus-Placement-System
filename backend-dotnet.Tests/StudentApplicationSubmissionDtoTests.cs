using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using backend_dotnet.DTOs;
using Xunit;

namespace backend_dotnet.Tests;

public class StudentApplicationSubmissionDtoTests
{
    [Theory]
    [InlineData(null)]
    [InlineData("00000000-0000-0000-0000-000000000000")]
    public void Request_RejectsMissingOrEmptyJobId(string? jobId)
    {
        var request = new StudentApplicationSubmissionRequestDto
        {
            JobId = jobId == null ? null : Guid.Parse(jobId)
        };

        var results = new List<ValidationResult>();
        var valid = Validator.TryValidateObject(
            request,
            new ValidationContext(request),
            results,
            validateAllProperties: true);

        Assert.False(valid);
        Assert.Contains(results, result => result.MemberNames.Contains(nameof(request.JobId)));
    }

    [Fact]
    public void Request_SerializesOnlyChosenJobId()
    {
        var jobId = Guid.NewGuid();
        var request = new StudentApplicationSubmissionRequestDto { JobId = jobId };
        var results = new List<ValidationResult>();

        Assert.True(Validator.TryValidateObject(
            request,
            new ValidationContext(request),
            results,
            validateAllProperties: true));

        using var json = JsonDocument.Parse(JsonSerializer.Serialize(request));
        Assert.Single(json.RootElement.EnumerateObject());
        Assert.Equal(jobId, json.RootElement.GetProperty("JobId").GetGuid());
    }

    [Fact]
    public void Response_SerializesOnlyReceiptFields()
    {
        var response = new StudentApplicationSubmissionResponseDto(
            Guid.NewGuid(), Guid.NewGuid(), "Pending");

        using var json = JsonDocument.Parse(JsonSerializer.Serialize(response));
        Assert.Equal(3, json.RootElement.EnumerateObject().Count());
        Assert.Equal(response.AppId, json.RootElement.GetProperty("AppId").GetGuid());
        Assert.Equal(response.JobId, json.RootElement.GetProperty("JobId").GetGuid());
        Assert.Equal("Pending", json.RootElement.GetProperty("Status").GetString());
    }
}
