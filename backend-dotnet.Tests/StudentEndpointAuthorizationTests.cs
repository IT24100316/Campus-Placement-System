using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using backend_dotnet.Controllers;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Xunit;

namespace backend_dotnet.Tests;

public class StudentEndpointAuthorizationTests
{
    private const string SigningKey = "StudentEndpointAuthorizationTests-Only-Secret-Key-2026";
    private static readonly (HttpMethod Method, string Path)[] StudentActions =
    [
        (HttpMethod.Get, "/api/Students/profile"),
        (HttpMethod.Put, "/api/Students/profile"),
        (HttpMethod.Post, "/api/Students/upload-cv"),
        (HttpMethod.Post, "/api/Applications/apply"),
        (HttpMethod.Get, "/api/Applications/me")
    ];

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(2)]
    [InlineData(3)]
    [InlineData(4)]
    public async Task MissingOrInvalidToken_IsRejectedByAuthorizationPipeline(int actionIndex)
    {
        using var server = CreateServer();
        using var client = server.CreateClient();
        var action = StudentActions[actionIndex];

        using var missing = await client.SendAsync(CreateRequest(action));
        Assert.Equal(HttpStatusCode.Unauthorized, missing.StatusCode);
        Assert.Contains(missing.Headers.WwwAuthenticate, challenge => challenge.Scheme == "Bearer");

        using var invalidRequest = CreateRequest(action);
        invalidRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", "not-a-valid-jwt");
        using var invalid = await client.SendAsync(invalidRequest);
        Assert.Equal(HttpStatusCode.Unauthorized, invalid.StatusCode);
        Assert.Contains(invalid.Headers.WwwAuthenticate, challenge => challenge.Scheme == "Bearer");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(2)]
    [InlineData(3)]
    [InlineData(4)]
    public async Task NonStudentToken_IsForbiddenByAuthorizationPipeline(int actionIndex)
    {
        using var server = CreateServer();
        using var client = server.CreateClient();
        var company = new User
        {
            Id = Guid.NewGuid(),
            Email = "company@example.com",
            Role = UserRole.Company
        };
        using var request = CreateRequest(StudentActions[actionIndex]);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(company));

        using var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Theory]
    [InlineData(0, HttpStatusCode.OK)]
    [InlineData(1, HttpStatusCode.OK)]
    [InlineData(2, HttpStatusCode.OK)]
    [InlineData(3, HttpStatusCode.Created)]
    [InlineData(4, HttpStatusCode.OK)]
    public async Task StudentToken_ReachesEachAction(int actionIndex, HttpStatusCode expectedStatus)
    {
        using var server = CreateServer();
        var student = await SeedStudentAsync(server);
        using var client = server.CreateClient();
        using var request = CreateRequest(StudentActions[actionIndex]);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(student));

        using var response = await client.SendAsync(request);

        Assert.True(
            response.StatusCode == expectedStatus,
            $"Expected {expectedStatus}, got {response.StatusCode}: {await response.Content.ReadAsStringAsync()}");
    }

    [Fact]
    public async Task MyApplications_ReturnsOnlyTheAuthenticatedStudentsApplications()
    {
        using var server = CreateServer();
        var student = await SeedStudentAsync(server);
        var otherStudent = new User
        {
            Id = Guid.NewGuid(),
            Email = "other-student@example.edu",
            Role = UserRole.Student,
            Status = AccountStatus.Approved
        };
        var ownApplicationId = Guid.NewGuid();
        var otherApplicationId = Guid.NewGuid();
        using (var scope = server.Services.CreateScope())
        {
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            context.Users.Add(otherStudent);
            context.Applications.AddRange(
                new Application
                {
                    AppId = ownApplicationId,
                    StudentId = student.Id,
                    JobId = SeededJobId,
                    SummaryReport = "{}"
                },
                new Application
                {
                    AppId = otherApplicationId,
                    StudentId = otherStudent.Id,
                    JobId = SeededJobId,
                    SummaryReport = "{}"
                });
            await context.SaveChangesAsync();
        }

        using var client = server.CreateClient();
        using var ownRequest = new HttpRequestMessage(
            HttpMethod.Get, $"/api/Applications/me?studentId={otherStudent.Id}");
        ownRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(student));
        using var ownResponse = await client.SendAsync(ownRequest);
        Assert.Equal(HttpStatusCode.OK, ownResponse.StatusCode);
        using var ownJson = JsonDocument.Parse(await ownResponse.Content.ReadAsStringAsync());
        var ownRow = Assert.Single(ownJson.RootElement.EnumerateArray());
        Assert.Equal(ownApplicationId, ownRow.GetProperty("applicationId").GetGuid());
        Assert.NotEqual(otherApplicationId, ownRow.GetProperty("applicationId").GetGuid());

        using var otherRequest = new HttpRequestMessage(HttpMethod.Get, "/api/Applications/me");
        otherRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(otherStudent));
        using var otherResponse = await client.SendAsync(otherRequest);
        Assert.Equal(HttpStatusCode.OK, otherResponse.StatusCode);
        using var otherJson = JsonDocument.Parse(await otherResponse.Content.ReadAsStringAsync());
        var otherRow = Assert.Single(otherJson.RootElement.EnumerateArray());
        Assert.Equal(otherApplicationId, otherRow.GetProperty("applicationId").GetGuid());
    }

    [Theory]
    [InlineData(null)]
    [InlineData("not-a-guid")]
    [InlineData("00000000-0000-0000-0000-000000000000")]
    public async Task MyApplications_InvalidOrMissingIdentityClaim_ReturnsUnauthorized(string? claimValue)
    {
        using var server = CreateServer();
        using var client = server.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/Applications/me");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", StudentTokenWithClaim(claimValue));

        using var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(
            "An authenticated student identity is required.",
            json.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task StudentClaim_DeterminesProfileAndApplicationOwner()
    {
        using var server = CreateServer();
        var student = await SeedStudentAsync(server);
        var otherStudentId = Guid.NewGuid();
        using var client = server.CreateClient();

        using var profileRequest = new HttpRequestMessage(
            HttpMethod.Get, $"/api/Students/profile?studentId={otherStudentId}");
        profileRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(student));
        using var profileResponse = await client.SendAsync(profileRequest);
        Assert.Equal(HttpStatusCode.OK, profileResponse.StatusCode);
        using var profileJson = JsonDocument.Parse(await profileResponse.Content.ReadAsStringAsync());
        Assert.Equal(student.Id, profileJson.RootElement.GetProperty("userId").GetGuid());

        var updateBody = JsonNode.Parse(JsonSerializer.Serialize(ValidProfileRequest()))!;
        updateBody["studentId"] = otherStudentId.ToString();
        updateBody["FullName"] = "Claim Owner";
        using var updateRequest = new HttpRequestMessage(HttpMethod.Put, "/api/Students/profile")
        {
            Content = JsonContent.Create(updateBody)
        };
        updateRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(student));
        using var updateResponse = await client.SendAsync(updateRequest);
        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);

        using var uploadRequest = CreateRequest(StudentActions[2]);
        uploadRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(student));
        ((MultipartFormDataContent)uploadRequest.Content!).Add(
            new StringContent(otherStudentId.ToString()), "studentId");
        using var uploadResponse = await client.SendAsync(uploadRequest);
        Assert.Equal(HttpStatusCode.OK, uploadResponse.StatusCode);

        using var scope = server.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var jobId = await context.Jobs.Select(job => job.JobId).SingleAsync();
        using var applyRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Applications/apply")
        {
            Content = JsonContent.Create(new { jobId, studentId = otherStudentId })
        };
        applyRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", TokenFor(student));
        using var applyResponse = await client.SendAsync(applyRequest);

        Assert.Equal(HttpStatusCode.Created, applyResponse.StatusCode);
        var application = await context.Applications.SingleAsync();
        Assert.Equal(student.Id, application.StudentId);
        Assert.NotEqual(otherStudentId, application.StudentId);
        var savedProfile = await context.StudentProfiles.SingleAsync();
        Assert.Equal(student.Id, savedProfile.UserId);
        Assert.Equal("Claim Owner", savedProfile.FullName);
        Assert.Equal($"{student.Id:N}/cv.pdf", savedProfile.CvPdfUrl);
    }

    private static TestServer CreateServer()
    {
        var configuration = TestConfiguration();
        var databaseName = Guid.NewGuid().ToString();
        var builder = new WebHostBuilder()
            .ConfigureServices(services =>
            {
                services.AddSingleton<IConfiguration>(configuration);
                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase(databaseName));
                services.AddControllers().AddApplicationPart(typeof(StudentsController).Assembly);
                services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                    .AddJwtBearer(options => options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = configuration["Jwt:Issuer"],
                        ValidAudience = configuration["Jwt:Audience"],
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SigningKey)),
                        ClockSkew = TimeSpan.Zero
                    });
                services.AddAuthorization();
                services.AddHttpClient();
                services.AddScoped<IApplicationService>(provider => new ApplicationService(
                    provider.GetRequiredService<AppDbContext>(),
                    provider.GetRequiredService<IHttpClientFactory>(),
                    configuration,
                    null!,
                    null!));
                services.AddScoped<ICvFileValidationService, AcceptPdfValidation>();
                services.AddScoped<ICvStorageService, InMemoryCvStorage>();
            })
            .Configure(app =>
            {
                app.UseRouting();
                app.UseAuthentication();
                app.UseAuthorization();
                app.UseEndpoints(endpoints => endpoints.MapControllers());
            });

        return new TestServer(builder);
    }

    private static IConfiguration TestConfiguration() => new ConfigurationBuilder()
        .AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = SigningKey,
            ["Jwt:Issuer"] = "StudentEndpointAuthorizationTests",
            ["Jwt:Audience"] = "StudentEndpointAuthorizationTests",
            ["Jwt:ExpiryMinutes"] = "60"
        })
        .Build();

    private static string TokenFor(User user) => new JwtService(TestConfiguration()).GenerateToken(user);

    private static string StudentTokenWithClaim(string? claimValue)
    {
        var claims = new List<Claim> { new(ClaimTypes.Role, "Student") };
        if (claimValue != null)
        {
            claims.Add(new Claim(ClaimTypes.NameIdentifier, claimValue));
        }

        var configuration = TestConfiguration();
        var token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"],
            audience: configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(60),
            signingCredentials: new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SigningKey)),
                SecurityAlgorithms.HmacSha256));
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static HttpRequestMessage CreateRequest((HttpMethod Method, string Path) action)
    {
        var request = new HttpRequestMessage(action.Method, action.Path);
        if (action.Path.EndsWith("upload-cv", StringComparison.Ordinal))
        {
            var form = new MultipartFormDataContent();
            var file = new ByteArrayContent("%PDF-test"u8.ToArray());
            file.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
            form.Add(file, "file", "cv.pdf");
            request.Content = form;
        }
        else if (action.Method != HttpMethod.Get)
        {
            request.Content = action.Path.EndsWith("apply", StringComparison.Ordinal)
                ? JsonContent.Create(new StudentApplicationSubmissionRequestDto { JobId = SeededJobId })
                : JsonContent.Create(ValidProfileRequest());
        }
        return request;
    }

    private static readonly Guid SeededJobId = Guid.Parse("0e769cb1-45c6-4b88-b6fb-a3fc0a38d64c");

    private static async Task<User> SeedStudentAsync(TestServer server)
    {
        using var scope = server.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var student = new User
        {
            Id = Guid.NewGuid(),
            Email = "student@example.edu",
            Role = UserRole.Student,
            Status = AccountStatus.Approved
        };
        var company = new User
        {
            Id = Guid.NewGuid(),
            Email = "employer@example.com",
            Role = UserRole.Company,
            Status = AccountStatus.Approved
        };
        context.Users.AddRange(student, company);
        context.CompanyProfiles.Add(new CompanyProfile
        {
            UserId = company.Id,
            CompanyName = "Test Employer",
            ContactPersonName = "Recruiter",
            ContactPersonEmail = company.Email,
            Phone = "+94111222333"
        });
        context.Jobs.Add(new Job
        {
            JobId = SeededJobId,
            CompanyId = company.Id,
            JobTitle = "Software Intern",
            ApplicationDeadline = DateTime.UtcNow.AddDays(30)
        });
        context.StudentProfiles.Add(new StudentProfile
        {
            UserId = student.Id,
            FullName = "Student One",
            Phone = "+94111222333",
            UniversityName = "Test University",
            AcademicStatus = "Full-time Student",
            DegreeProgram = "Software Engineering",
            CurrentYearOfStudy = 3,
            GPA = 3.5m,
            ExpectedGraduationDate = DateTime.UtcNow.Date.AddYears(1),
            DesiredJobTitle = "Software Intern",
            PrimaryDomain = "Software Engineering",
            CareerObjectivesSummary = "Build reliable software as an intern.",
            Skills = ["C#"],
            ToolsAndTechnologies = ["Git"],
            InternshipType = ["Hybrid"],
            LectureScheduleType = "Weekday",
            PreferredLocations = ["Colombo"],
            CvPdfUrl = "student/cv.pdf"
        });
        await context.SaveChangesAsync();
        return student;
    }

    private static StudentProfileUpsertRequest ValidProfileRequest() => new()
    {
        FullName = "Student One",
        Phone = "+94111222333",
        UniversityName = "Test University",
        AcademicStatus = "Full-time Student",
        DegreeProgram = "Software Engineering",
        CurrentYearOfStudy = 3,
        GPA = 3.5m,
        ExpectedGraduationDate = DateTime.UtcNow.Date.AddYears(1),
        DesiredJobTitle = "Software Intern",
        PrimaryDomain = "Software Engineering",
        CareerObjectivesSummary = "Build reliable software as an intern.",
        Skills = ["C#"],
        ToolsAndTechnologies = ["Git"],
        InternshipType = ["Hybrid"],
        LectureScheduleType = "Weekday",
        PreferredLocations = ["Colombo"]
    };

    private sealed class AcceptPdfValidation : ICvFileValidationService
    {
        public Task<CvFileValidationResult> ValidateAsync(
            IFormFile? file, CancellationToken cancellationToken = default) =>
            Task.FromResult(CvFileValidationResult.Valid());
    }

    private sealed class InMemoryCvStorage : ICvStorageService
    {
        public Task<string> StoreAsync(
            Guid studentId, IFormFile file, CancellationToken cancellationToken = default) =>
            Task.FromResult($"{studentId:N}/cv.pdf");

        public Task DeleteAsync(string storageKey, CancellationToken cancellationToken = default) =>
            Task.CompletedTask;
    }
}
