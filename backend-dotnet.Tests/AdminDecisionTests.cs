using backend_dotnet.Data;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Tests;

public class AdminDecisionTests
{
    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task AccountDecisionCanBeMadeOnlyOnce(bool approve)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var db = new AppDbContext(options);
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "pending@example.edu",
            Role = UserRole.Student,
            Status = AccountStatus.Pending,
            PasswordHash = "test-only"
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        var email = new CountingEmailService();
        var service = new AdminService(db, email);

        if (approve)
            await service.ApproveUserAsync(user.Id.ToString());
        else
            await service.RejectUserAsync(user.Id.ToString());

        Assert.Equal(approve ? AccountStatus.Approved : AccountStatus.Rejected, user.Status);
        Assert.Equal(1, email.SendCount);
        if (approve)
            await Assert.ThrowsAsync<InvalidOperationException>(() => service.ApproveUserAsync(user.Id.ToString()));
        else
            await Assert.ThrowsAsync<InvalidOperationException>(() => service.RejectUserAsync(user.Id.ToString()));
        Assert.Equal(1, email.SendCount);
    }

    private sealed class CountingEmailService : IEmailService
    {
        public int SendCount { get; private set; }

        public Task<bool> SendAccountDecisionAsync(string recipient, string displayName, bool approved, CancellationToken cancellationToken = default)
        {
            SendCount++;
            return Task.FromResult(true);
        }

        public Task<bool> SendInterviewScheduledAsync(string toEmail, string studentName, string companyName, string jobTitle, DateTime interviewDate, TimeSpan interviewTime, string? meetingLink, CancellationToken cancellationToken = default) => Task.FromResult(true);
        public Task<bool> SendCandidateRejectedAsync(string toEmail, string studentName, string companyName, string jobTitle, string reason, CancellationToken cancellationToken = default) => Task.FromResult(true);
    }
}
