using System.Text.Json;
using backend_dotnet.Controllers;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Tests;

public class AuthControllerTests
{
    [Fact]
    public async Task Login_ReturnsApprovedStudentIdentity()
    {
        await using var db = CreateDb();
        var user = AddStudent(db, AccountStatus.Approved, "student@example.edu", "GoodPassword1!");
        var controller = new AuthController(new AuthService(db, new FakeStorage()));

        var result = await controller.Login(new LoginDto { Email = "student@example.edu", Password = "GoodPassword1!" });

        var ok = Assert.IsType<OkObjectResult>(result);
        var json = JsonSerializer.Serialize(ok.Value);
        Assert.Contains(user.Id.ToString(), json);
        Assert.Contains("\"success\":true", json);
        Assert.Contains("Student", json);
    }

    [Fact]
    public async Task Login_ReturnsPendingGate()
    {
        await using var db = CreateDb();
        AddStudent(db, AccountStatus.Pending, "pending@example.edu", "GoodPassword1!");
        var controller = new AuthController(new AuthService(db, new FakeStorage()));

        var result = await controller.Login(new LoginDto { Email = "pending@example.edu", Password = "GoodPassword1!" });

        var ok = Assert.IsType<OkObjectResult>(result);
        var json = JsonSerializer.Serialize(ok.Value);
        Assert.Contains("\"isPending\":true", json);
    }

    [Fact]
    public async Task Login_RejectsWrongPassword()
    {
        await using var db = CreateDb();
        AddStudent(db, AccountStatus.Approved, "student@example.edu", "GoodPassword1!");
        var controller = new AuthController(new AuthService(db, new FakeStorage()));

        var result = await controller.Login(new LoginDto { Email = "student@example.edu", Password = "wrong" });

        Assert.IsType<UnauthorizedObjectResult>(result);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static User AddStudent(AppDbContext db, AccountStatus status, string email, string password)
    {
        var user = new User { Id = Guid.NewGuid(), Email = email, Role = UserRole.Student, Status = status };
        user.PasswordHash = new PasswordHasher<User>().HashPassword(user, password);
        user.StudentProfile = new StudentProfile { UserId = user.Id, FullName = "Test Student", Phone = "123", UniversityName = "Test University" };
        db.Users.Add(user);
        db.SaveChanges();
        return user;
    }

    private sealed class FakeStorage : IDocumentStorageService
    {
        public Task<StoredDocument> UploadAsync(IFormFile file, string folder, CancellationToken cancellationToken = default) =>
            Task.FromResult(new StoredDocument("local://test.pdf", file.FileName, file.ContentType));
        public Task<(Stream Content, string ContentType, string FileName)?> OpenReadAsync(string storageKey, CancellationToken cancellationToken = default) =>
            Task.FromResult<(Stream, string, string)?>(null);
    }
}
