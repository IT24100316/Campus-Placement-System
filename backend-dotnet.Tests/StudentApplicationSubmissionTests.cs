using System.Security.Claims;
using System.Text.Json;
using backend_dotnet.Controllers;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace backend_dotnet.Tests;

public class StudentApplicationSubmissionTests
{
    [Fact]
    public async Task ValidStudent_CreatesPendingApplicationAndReturnsReceipt()
    {
        await using var context = CreateContext();
        var (studentId, jobId) = await SeedValidScenario(context);
        var controller = CreateController(context, studentId.ToString());

        var result = await controller.Apply(
            new StudentApplicationSubmissionRequestDto { JobId = jobId },
            CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var receipt = Assert.IsType<StudentApplicationSubmissionResponseDto>(created.Value);
        var application = await context.Applications.SingleAsync();

        Assert.Equal(application.AppId, receipt.AppId);
        Assert.Equal(jobId, receipt.JobId);
        Assert.Equal("Pending", receipt.Status);
        Assert.Equal(studentId, application.StudentId);
        Assert.Equal(jobId, application.JobId);
        Assert.Equal(ApplicationStatus.Pending, application.Status);
        Assert.Equal(0, application.MatchScore);
        using var summary = JsonDocument.Parse(application.SummaryReport);
        Assert.Equal(JsonValueKind.Object, summary.RootElement.ValueKind);
        Assert.Empty(summary.RootElement.EnumerateObject());
    }

    [Fact]
    public async Task SameStudentAndJob_SecondSubmissionIsRejectedWithoutAnotherInsert()
    {
        await using var context = CreateContext();
        var (studentId, jobId) = await SeedValidScenario(context);
        var service = CreateService(context);
        await service.SubmitStudentApplicationAsync(studentId, jobId, CancellationToken.None);

        var error = await Assert.ThrowsAsync<StudentApplicationSubmissionException>(
            () => service.SubmitStudentApplicationAsync(studentId, jobId, CancellationToken.None));

        Assert.Equal(StudentApplicationSubmissionError.Duplicate, error.Error);
        Assert.Equal(1, await context.Applications.CountAsync());
    }

    [Theory]
    [InlineData("expired", StudentApplicationSubmissionError.ExpiredJob)]
    [InlineData("missing-profile", StudentApplicationSubmissionError.InvalidProfile)]
    [InlineData("incomplete-profile", StudentApplicationSubmissionError.InvalidProfile)]
    [InlineData("missing-cv", StudentApplicationSubmissionError.InvalidProfile)]
    [InlineData("missing-job", StudentApplicationSubmissionError.JobNotFound)]
    [InlineData("non-student", StudentApplicationSubmissionError.Forbidden)]
    [InlineData("missing-user", StudentApplicationSubmissionError.Unauthorized)]
    public async Task InvalidSubmission_DoesNotInsertApplication(
        string scenario, StudentApplicationSubmissionError expectedError)
    {
        await using var context = CreateContext();
        var (studentId, jobId) = await SeedValidScenario(context);

        switch (scenario)
        {
            case "expired":
                (await context.Jobs.SingleAsync()).ApplicationDeadline = DateTime.UtcNow.AddDays(-1);
                break;
            case "missing-profile":
                context.StudentProfiles.Remove(await context.StudentProfiles.SingleAsync());
                break;
            case "incomplete-profile":
                (await context.StudentProfiles.SingleAsync()).UniversityName = " ";
                break;
            case "missing-cv":
                (await context.StudentProfiles.SingleAsync()).CvPdfUrl = " ";
                break;
            case "missing-job":
                jobId = Guid.NewGuid();
                break;
            case "non-student":
                (await context.Users.SingleAsync(user => user.Id == studentId)).Role = UserRole.Company;
                break;
            case "missing-user":
                studentId = Guid.NewGuid();
                break;
        }

        await context.SaveChangesAsync();
        var error = await Assert.ThrowsAsync<StudentApplicationSubmissionException>(
            () => CreateService(context).SubmitStudentApplicationAsync(
                studentId, jobId, CancellationToken.None));

        Assert.Equal(expectedError, error.Error);
        Assert.Empty(await context.Applications.ToListAsync());
    }

    [Theory]
    [InlineData(null, false)]
    [InlineData("not-a-guid", true)]
    [InlineData("00000000-0000-0000-0000-000000000000", true)]
    public async Task MissingOrInvalidIdentity_ReturnsUnauthorizedWithoutInsert(
        string? claimValue, bool authenticated)
    {
        await using var context = CreateContext();
        var (_, jobId) = await SeedValidScenario(context);
        var controller = CreateController(context, claimValue, authenticated);

        var result = await controller.Apply(
            new StudentApplicationSubmissionRequestDto { JobId = jobId },
            CancellationToken.None);

        Assert.IsType<UnauthorizedObjectResult>(result);
        Assert.Empty(await context.Applications.ToListAsync());
    }

    [Theory]
    [InlineData("duplicate")]
    [InlineData("expired")]
    public async Task Controller_MapsDuplicateAndExpiredJobToConflict(string scenario)
    {
        await using var context = CreateContext();
        var (studentId, jobId) = await SeedValidScenario(context);
        if (scenario == "duplicate")
        {
            await CreateService(context).SubmitStudentApplicationAsync(
                studentId, jobId, CancellationToken.None);
        }
        else
        {
            (await context.Jobs.SingleAsync()).ApplicationDeadline = DateTime.UtcNow.AddDays(-1);
            await context.SaveChangesAsync();
        }

        var controller = CreateController(context, studentId.ToString());
        var result = await controller.Apply(
            new StudentApplicationSubmissionRequestDto { JobId = jobId },
            CancellationToken.None);

        var conflict = Assert.IsType<ConflictObjectResult>(result);
        using var message = JsonDocument.Parse(JsonSerializer.Serialize(conflict.Value));
        Assert.False(string.IsNullOrWhiteSpace(message.RootElement.GetProperty("message").GetString()));
        Assert.Equal(scenario == "duplicate" ? 1 : 0, await context.Applications.CountAsync());
    }

    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<(Guid StudentId, Guid JobId)> SeedValidScenario(AppDbContext context)
    {
        var studentId = Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var jobId = Guid.NewGuid();

        context.Users.AddRange(
            new User
            {
                Id = studentId,
                Email = "student@example.edu",
                PasswordHash = "test-only",
                Role = UserRole.Student,
                Status = AccountStatus.Approved
            },
            new User
            {
                Id = companyId,
                Email = "company@example.com",
                PasswordHash = "test-only",
                Role = UserRole.Company,
                Status = AccountStatus.Approved
            });
        context.CompanyProfiles.Add(new CompanyProfile
        {
            UserId = companyId,
            CompanyName = "Example Company",
            Industry = "Software",
            ContactPersonName = "Recruiter",
            ContactPersonEmail = "company@example.com",
            Phone = "+94111222333"
        });
        context.Jobs.Add(new Job
        {
            JobId = jobId,
            CompanyId = companyId,
            JobTitle = "Software Intern",
            TargetDomain = "Software Engineering",
            ApplicationDeadline = DateTime.UtcNow.AddDays(30)
        });
        context.StudentProfiles.Add(new StudentProfile
        {
            UserId = studentId,
            FullName = "Alex Student",
            Phone = "+94111222333",
            UniversityName = "Example University",
            AcademicStatus = "Full-time Student",
            DegreeProgram = "Software Engineering",
            CurrentYearOfStudy = 3,
            GPA = 3.5m,
            ExpectedGraduationDate = DateTime.UtcNow.Date.AddYears(1),
            DesiredJobTitle = "Software Intern",
            PrimaryDomain = "Software Engineering",
            CareerObjectivesSummary = "Build useful software systems.",
            Skills = new[] { "C#" },
            ToolsAndTechnologies = new[] { "Git" },
            InternshipType = new[] { "Hybrid" },
            LectureScheduleType = "Weekday",
            PreferredLocations = new[] { "Colombo" },
            CvPdfUrl = "student/cv.pdf"
        });
        await context.SaveChangesAsync();
        return (studentId, jobId);
    }

    private static ApplicationsController CreateController(
        AppDbContext context, string? claimValue, bool authenticated = true)
    {
        var claims = claimValue == null
            ? Array.Empty<Claim>()
            : new[] { new Claim(ClaimTypes.NameIdentifier, claimValue) };
        var identity = new ClaimsIdentity(
            claims, authenticated ? "TestAuthentication" : null);
        return new ApplicationsController(CreateService(context))
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(identity)
                }
            }
        };
    }

    private static ApplicationService CreateService(AppDbContext context) =>
        new(context, null!, null!, null!, null!);
}
