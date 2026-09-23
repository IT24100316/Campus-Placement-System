using System.Security.Claims;
using backend_dotnet.Configuration;
using backend_dotnet.Controllers;
using backend_dotnet.Data;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
        context.StudentProfiles.Add(new StudentProfile { UserId = studentId });
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
        Assert.Equal(storageKey, (await context.StudentProfiles.SingleAsync()).CvPdfUrl);
    }

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

        return new StudentsController(context, validationService, storageService)
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

        public StubStorageService(string storageKey)
        {
            _storageKey = storageKey;
        }

        public Task<string> StoreAsync(Guid studentId, IFormFile file, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(_storageKey);
        }

        public Task DeleteAsync(string storageKey, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
    }
}
