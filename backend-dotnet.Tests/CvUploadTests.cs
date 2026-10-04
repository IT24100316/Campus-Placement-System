using System.Security.Claims;
using backend_dotnet.Configuration;
using backend_dotnet.Controllers;
using backend_dotnet.Data;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Xunit;

namespace backend_dotnet.Tests;

public class CvUploadTests
{
    [Fact]
    public async Task ValidateAsync_RejectsNonPdfContentType()
    {
        var service = CreateValidationService();
        var file = CreateFile("resume.pdf", "text/plain", "%PDF-test"u8.ToArray());

        var result = await service.ValidateAsync(file);

        Assert.False(result.IsValid);
        Assert.Equal("The CV must use the application/pdf content type.", result.ErrorMessage);
    }

    [Fact]
    public async Task ValidateAsync_RejectsFilesOverConfiguredLimit()
    {
        var service = CreateValidationService(maxFileSizeBytes: 5);
        var file = CreateFile("resume.pdf", "application/pdf", "%PDF-too-large"u8.ToArray());

        var result = await service.ValidateAsync(file);

        Assert.False(result.IsValid);
        Assert.Equal("The CV must not exceed 5 bytes.", result.ErrorMessage);
    }

    [Fact]
    public async Task UploadCv_PersistsStorageKeyForAuthenticatedStudent()
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
        context.StudentProfiles.Add(CompleteProfile(studentId));
        await context.SaveChangesAsync();

        var storageKey = $"{studentId:N}/generated-cv.pdf";
        var controller = CreateController(
            context,
            studentId,
            new StubValidationService(CvFileValidationResult.Valid()),
            new StubStorageService(storageKey));

        var result = await controller.UploadCv(
            CreateFile("resume.pdf", "application/pdf", "%PDF-test"u8.ToArray()),
            CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
        var savedProfile = await context.StudentProfiles.SingleAsync();
        Assert.Equal(storageKey, savedProfile.CvPdfUrl);
        Assert.NotNull(savedProfile.CvUploadedAt);
        Assert.Empty(await context.Applications.ToListAsync());
    }

    [Fact]
    public async Task UploadCv_RejectsReplacementBeforeCooldownWithoutStoringOrDeletingFiles()
    {
        var studentId = Guid.NewGuid();
        var oldKey = $"{studentId:N}/old.pdf";
        await using var context = CreateContext();
        context.Users.Add(StudentUser(studentId));
        var profile = CompleteProfile(studentId);
        profile.CvPdfUrl = oldKey;
        profile.CvUploadedAt = DateTime.UtcNow.AddDays(-6).AddHours(-23);
        context.StudentProfiles.Add(profile);
        await context.SaveChangesAsync();

        var storage = new StubStorageService($"{studentId:N}/new.pdf");
        var result = await CreateController(
            context,
            studentId,
            new StubValidationService(CvFileValidationResult.Valid()),
            storage).UploadCv(
                CreateFile("resume.pdf", "application/pdf", "%PDF-test"u8.ToArray()),
                CancellationToken.None);

        var conflict = Assert.IsType<ConflictObjectResult>(result);
        Assert.Contains("You can update your CV again on", conflict.Value!.ToString());
        Assert.Equal(0, storage.StoreCount);
        Assert.Empty(storage.DeletedKeys);
        var unchangedProfile = await context.StudentProfiles.SingleAsync();
        Assert.Equal(oldKey, unchangedProfile.CvPdfUrl);
    }

    [Fact]
    public async Task UploadCv_AllowsReplacementAfterSevenFullDays()
    {
        var studentId = Guid.NewGuid();
        var oldKey = $"{studentId:N}/old.pdf";
        var newKey = $"{studentId:N}/new.pdf";
        await using var context = CreateContext();
        context.Users.Add(StudentUser(studentId));
        var profile = CompleteProfile(studentId);
        profile.CvPdfUrl = oldKey;
        profile.CvUploadedAt = DateTime.UtcNow.AddDays(-7);
        context.StudentProfiles.Add(profile);
        await context.SaveChangesAsync();

        var storage = new StubStorageService(newKey);
        var result = await CreateController(
            context,
            studentId,
            new StubValidationService(CvFileValidationResult.Valid()),
            storage).UploadCv(
                CreateFile("resume.pdf", "application/pdf", "%PDF-test"u8.ToArray()),
                CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
        Assert.Equal(1, storage.StoreCount);
        Assert.Equal(oldKey, Assert.Single(storage.DeletedKeys));
        Assert.Equal(newKey, (await context.StudentProfiles.SingleAsync()).CvPdfUrl);
    }

    [Fact]
    public async Task UploadCv_AllowsLegacyCvWithoutUploadTimestampOnce()
    {
        var studentId = Guid.NewGuid();
        var oldKey = $"{studentId:N}/old.pdf";
        var newKey = $"{studentId:N}/new.pdf";
        await using var context = CreateContext();
        context.Users.Add(StudentUser(studentId));
        var profile = CompleteProfile(studentId);
        profile.CvPdfUrl = oldKey;
        profile.CvUploadedAt = null;
        context.StudentProfiles.Add(profile);
        await context.SaveChangesAsync();

        var storage = new StubStorageService(newKey);
        var result = await CreateController(
            context,
            studentId,
            new StubValidationService(CvFileValidationResult.Valid()),
            storage).UploadCv(
                CreateFile("resume.pdf", "application/pdf", "%PDF-test"u8.ToArray()),
                CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
        var savedProfile = await context.StudentProfiles.SingleAsync();
        Assert.Equal(newKey, savedProfile.CvPdfUrl);
        Assert.NotNull(savedProfile.CvUploadedAt);
    }

    [Fact]
    public async Task UploadCv_PreviousDeleteFailureDoesNotUndoCompletedReplacement()
    {
        var studentId = Guid.NewGuid();
        var oldKey = $"{studentId:N}/{Guid.NewGuid():N}.pdf";
        var newKey = $"{studentId:N}/{Guid.NewGuid():N}.pdf";
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId, Email = "student@example.edu", PasswordHash = "test-only",
            Role = UserRole.Student, Status = AccountStatus.Approved
        });
        var profile = CompleteProfile(studentId);
        profile.CvPdfUrl = oldKey;
        context.StudentProfiles.Add(profile);
        await context.SaveChangesAsync();
        var storage = new StubStorageService(newKey) { DeleteException = new CvStorageException("cleanup failed") };
        var controller = CreateController(context, studentId,
            new StubValidationService(CvFileValidationResult.Valid()), storage);

        var result = await controller.UploadCv(
            CreateFile("resume.pdf", "application/pdf", "%PDF-test"u8.ToArray()), CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
        Assert.Equal(newKey, (await context.StudentProfiles.SingleAsync()).CvPdfUrl);
        Assert.Equal(oldKey, Assert.Single(storage.DeletedKeys));
        Assert.Equal(1, storage.StoreCount);
    }

    [Fact]
    public async Task UploadCv_RejectsIncompleteProfileWithoutStoringFile()
    {
        var studentId = Guid.NewGuid();
        await using var context = CreateContext();
        context.Users.Add(new User
        {
            Id = studentId, Email = "student@example.edu", PasswordHash = "test-only",
            Role = UserRole.Student, Status = AccountStatus.Approved
        });
        context.StudentProfiles.Add(new StudentProfile { UserId = studentId, FullName = "Student" });
        await context.SaveChangesAsync();
        var storage = new StubStorageService("should-not-be-stored");
        var controller = CreateController(context, studentId,
            new StubValidationService(CvFileValidationResult.Valid()), storage);

        var result = await controller.UploadCv(
            CreateFile("resume.pdf", "application/pdf", "%PDF-test"u8.ToArray()), CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Contains("Complete the required internship profile", badRequest.Value!.ToString());
        Assert.Equal(0, storage.StoreCount);
        Assert.Empty((await context.StudentProfiles.SingleAsync()).CvPdfUrl);
    }

    [Fact]
    public async Task LocalStorage_ClosesTemporaryFileBeforeMovingIt()
    {
        var testRoot = Path.Combine(Path.GetTempPath(), $"cv-storage-test-{Guid.NewGuid():N}");
        var storageRoot = Path.Combine(testRoot, "storage");
        var contentRoot = Path.Combine(testRoot, "content");
        Directory.CreateDirectory(contentRoot);

        try
        {
            var service = new LocalCvStorageService(
                Options.Create(new CvStorageOptions { RootPath = storageRoot }),
                new TestWebHostEnvironment(contentRoot));
            var studentId = Guid.NewGuid();

            var storageKey = await service.StoreAsync(
                studentId,
                CreateFile("resume.pdf", "application/pdf", "%PDF-test"u8.ToArray()));

            var storedPath = Path.Combine(storageRoot, storageKey.Replace('/', Path.DirectorySeparatorChar));
            Assert.True(File.Exists(storedPath));
            Assert.Equal("%PDF-test"u8.ToArray(), await File.ReadAllBytesAsync(storedPath));
            Assert.Empty(Directory.GetFiles(Path.GetDirectoryName(storedPath)!, "*.uploading"));
        }
        finally
        {
            if (Directory.Exists(testRoot))
            {
                Directory.Delete(testRoot, recursive: true);
            }
        }
    }

    private static StudentProfile CompleteProfile(Guid studentId) => new()
    {
        UserId = studentId, FullName = "Alex Student", Phone = "+94111222333",
        UniversityName = "Example University", AcademicStatus = "Full-time Student",
        DegreeProgram = "Software Engineering", CurrentYearOfStudy = 3,
        GPA = 3.5m, ExpectedGraduationDate = DateTime.UtcNow.Date.AddYears(1),
        DesiredJobTitle = "Software Intern", PrimaryDomain = "Software Engineering",
        CareerObjectivesSummary = "Build useful software systems.",
        Skills = new[] { "C#" }, ToolsAndTechnologies = new[] { "Git" },
        InternshipType = new[] { "Hybrid" }, LectureScheduleType = "Weekday",
        PreferredLocations = new[] { "Colombo" }
    };

    private static User StudentUser(Guid studentId) => new()
    {
        Id = studentId,
        Email = "student@example.edu",
        PasswordHash = "test-only",
        Role = UserRole.Student,
        Status = AccountStatus.Approved
    };

    private static CvFileValidationService CreateValidationService(long? maxFileSizeBytes = null)
    {
        return new CvFileValidationService(Options.Create(new CvStorageOptions
        {
            MaxFileSizeBytes = maxFileSizeBytes ?? CvStorageOptions.DefaultMaxFileSizeBytes
        }));
    }

    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    private static StudentsController CreateController(
        AppDbContext context,
        Guid studentId,
        ICvFileValidationService validationService,
        ICvStorageService storageService)
    {
        var identity = new ClaimsIdentity(
            new[] { new Claim(ClaimTypes.NameIdentifier, studentId.ToString()) },
            authenticationType: "TestAuthentication");

        return new StudentsController(
            context,
            validationService,
            storageService,
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

    private static IFormFile CreateFile(string fileName, string contentType, byte[] content)
    {
        return new FormFile(new MemoryStream(content), 0, content.Length, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = contentType
        };
    }

    private sealed class StubValidationService : ICvFileValidationService
    {
        private readonly CvFileValidationResult _result;

        public StubValidationService(CvFileValidationResult result)
        {
            _result = result;
        }

        public Task<CvFileValidationResult> ValidateAsync(
            IFormFile? file,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(_result);
        }
    }

    private sealed class StubStorageService : ICvStorageService
    {
        private readonly string _storageKey;
        public int StoreCount { get; private set; }
        public Exception? DeleteException { get; init; }
        public List<string> DeletedKeys { get; } = new();

        public StubStorageService(string storageKey)
        {
            _storageKey = storageKey;
        }

        public Task<string> StoreAsync(Guid studentId, IFormFile file, CancellationToken cancellationToken = default)
        {
            StoreCount++;
            return Task.FromResult(_storageKey);
        }

        public Task DeleteAsync(string storageKey, CancellationToken cancellationToken = default)
        {
            DeletedKeys.Add(storageKey);
            if (DeleteException != null) throw DeleteException;
            return Task.CompletedTask;
        }
    }

    private sealed class TestWebHostEnvironment : IWebHostEnvironment
    {
        public TestWebHostEnvironment(string contentRootPath)
        {
            ContentRootPath = contentRootPath;
        }

        public string ApplicationName { get; set; } = "backend-dotnet.Tests";
        public IFileProvider WebRootFileProvider { get; set; } = new NullFileProvider();
        public string WebRootPath { get; set; } = string.Empty;
        public string EnvironmentName { get; set; } = Environments.Development;
        public string ContentRootPath { get; set; }
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    }
}
