using System.Security.Claims;
using backend_dotnet.Controllers;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace backend_dotnet.Tests;

public class StudentProfileControllerTests
{
    [Fact]
    public async Task SaveProfile_CreatesProfileForAuthenticatedStudent()
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId,
            Email = "student@example.edu",
            PasswordHash = "not-used-by-this-test",
            Role = UserRole.Student,
            Status = AccountStatus.Approved
        });
        await context.SaveChangesAsync();

        var controller = CreateController(context, studentId);
        var request = CreateValidRequest();

        var result = await controller.SaveProfile(request);

        var created = Assert.IsType<CreatedAtActionResult>(result);
        var response = Assert.IsType<StudentProfileResponse>(created.Value);
        var savedProfile = await context.StudentProfiles.SingleAsync();

        Assert.Equal(studentId, response.UserId);
        Assert.Equal("Ada Lovelace", savedProfile.FullName);
        Assert.Equal(new[] { "C#", "PostgreSQL" }, savedProfile.Skills);
        Assert.Empty(savedProfile.CvPdfUrl);
    }

    [Fact]
    public async Task SaveProfile_PreservesPreviouslyUploadedCv()
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId, Email = "student@example.edu", PasswordHash = "test-only",
            Role = UserRole.Student, Status = AccountStatus.Approved
        });
        context.StudentProfiles.Add(new StudentProfile
        {
            UserId = studentId, FullName = "Earlier Name", CvPdfUrl = "student/existing-cv.pdf"
        });
        await context.SaveChangesAsync();

        var result = await CreateController(context, studentId).SaveProfile(CreateValidRequest());

        var response = Assert.IsType<StudentProfileResponse>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal("student/existing-cv.pdf", response.CvPdfUrl);
        Assert.Equal("student/existing-cv.pdf", (await context.StudentProfiles.SingleAsync()).CvPdfUrl);
    }

    [Fact]
    public async Task SaveProfile_AcceptsPartialDraftForAuthenticatedStudent()
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId,
            Email = "student@example.edu",
            PasswordHash = "not-used-by-this-test",
            Role = UserRole.Student,
            Status = AccountStatus.Approved
        });
        await context.SaveChangesAsync();

        var result = await CreateController(context, studentId).SaveProfile(new StudentProfileUpsertRequest
        {
            FullName = "Draft Student",
            IsDraft = true
        });

        Assert.IsType<CreatedAtActionResult>(result);
        var savedProfile = await context.StudentProfiles.SingleAsync();
        Assert.Equal("Draft Student", savedProfile.FullName);
        Assert.Equal(0, savedProfile.GPA);
        Assert.Null(savedProfile.ExpectedGraduationDate);
        Assert.Empty(savedProfile.CvPdfUrl);
    }

    [Theory]
    [InlineData("0712345678")]
    [InlineData("+94712345678")]
    public async Task SaveProfile_AcceptsValidSriLankanMobileDraft(string phone)
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId, Email = "student@example.edu", PasswordHash = "test-only",
            Role = UserRole.Student, Status = AccountStatus.Approved
        });
        await context.SaveChangesAsync();

        var result = await CreateController(context, studentId).SaveProfile(new StudentProfileUpsertRequest
        {
            FullName = "Åsa O'Neill",
            Phone = phone,
            UniversityName = "Campus University",
            IsDraft = true
        });

        Assert.IsType<CreatedAtActionResult>(result);
    }

    [Theory]
    [InlineData("071234567")]
    [InlineData("+94111222333")]
    [InlineData("07123abc78")]
    public async Task SaveProfile_RejectsMalformedEnteredDraftValues(string phone)
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId, Email = "student@example.edu", PasswordHash = "test-only",
            Role = UserRole.Student, Status = AccountStatus.Approved
        });
        await context.SaveChangesAsync();

        var result = await CreateController(context, studentId).SaveProfile(new StudentProfileUpsertRequest
        {
            Phone = phone,
            PortfolioUrl = "http://example.edu",
            IsDraft = true
        });

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(await context.StudentProfiles.ToListAsync());
    }

    [Fact]
    public async Task SaveProfile_RejectsNonHttpsPortfolioUrlInDraft()
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId, Email = "student@example.edu", PasswordHash = "test-only",
            Role = UserRole.Student, Status = AccountStatus.Approved
        });
        await context.SaveChangesAsync();

        var result = await CreateController(context, studentId).SaveProfile(new StudentProfileUpsertRequest
        {
            Phone = "0771234567",
            PortfolioUrl = "http://example.edu",
            IsDraft = true
        });

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task SaveProfile_RejectsShortCareerObjectiveAndDuplicateSkills()
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId, Email = "student@example.edu", PasswordHash = "test-only",
            Role = UserRole.Student, Status = AccountStatus.Approved
        });
        await context.SaveChangesAsync();

        var request = CreateValidRequest();
        request.CareerObjectivesSummary = "Too short";
        request.Skills = new[] { "Dart", "dart" };

        var result = await CreateController(context, studentId).SaveProfile(request);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task SaveProfile_RejectsInvalidValuesForFinalRegistration()
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId,
            Email = "student@example.edu",
            PasswordHash = "not-used-by-this-test",
            Role = UserRole.Student,
            Status = AccountStatus.Approved
        });
        await context.SaveChangesAsync();

        var request = CreateValidRequest();
        request.GPA = 4.5m;
        request.ExpectedGraduationDate = DateTime.UtcNow.Date.AddDays(-1);

        var result = await CreateController(context, studentId).SaveProfile(request);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(await context.StudentProfiles.ToListAsync());
    }

    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    private static StudentsController CreateController(AppDbContext context, Guid studentId)
    {
        var identity = new ClaimsIdentity(
            new[] { new Claim(ClaimTypes.NameIdentifier, studentId.ToString()) },
            authenticationType: "TestAuthentication");

        return new StudentsController(
            context,
            null!,
            null!,
            NullLogger<StudentsController>.Instance)
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

    private static StudentProfileUpsertRequest CreateValidRequest()
    {
        return new StudentProfileUpsertRequest
        {
            FullName = "Ada Lovelace",
            Phone = "+94771234567",
            UniversityName = "Example University",
            AcademicStatus = "Full-time Student",
            DegreeProgram = "B.Sc. Computer Science",
            CurrentYearOfStudy = 3,
            GPA = 3.8m,
            ExpectedGraduationDate = DateTime.UtcNow.Date.AddYears(1),
            DesiredJobTitle = "Software Engineering Intern",
            PrimaryDomain = "Software Engineering",
            CareerObjectivesSummary = "Build reliable software systems as an intern.",
            Skills = new[] { "C#", "PostgreSQL" },
            ToolsAndTechnologies = new[] { "Git" },
            InternshipType = new[] { "Hybrid" },
            LectureScheduleType = "Weekdays",
            PreferredLocations = new[] { "Colombo" }
        };
    }
}
