using backend_dotnet.Data;
using backend_dotnet.Models;
using backend_dotnet.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace backend_dotnet.Tests;

public class CompanyShortlistApprovalTests
{
    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task Approval_SendsEmailAndChangesStatusOnlyWhenDeliverySucceeds(bool emailSucceeds)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;
        await using var context = new AppDbContext(options);
        var student = new User { Email = "student@example.edu", Role = UserRole.Student };
        var company = new User { Email = "company@example.edu", Role = UserRole.Company };
        var companyProfile = new CompanyProfile { UserId = company.Id, User = company, CompanyName = "Example Company" };
        var job = new Job { CompanyId = company.Id, Company = companyProfile, JobTitle = "Engineering Intern" };
        var application = new Application
        {
            StudentId = student.Id, Student = student, JobId = job.JobId, Job = job,
            Status = ApplicationStatus.Student_Accepted, SummaryReport = "{}"
        };
        context.Users.AddRange(student, company);
        context.CompanyProfiles.Add(companyProfile);
        context.Jobs.Add(job);
        context.Applications.Add(application);
        await context.SaveChangesAsync();

        var email = new RecordingEmailService { Succeeds = emailSucceeds };
        var service = new ApplicationService(context, null!, new ConfigurationBuilder().Build(), email, null!);

        var approved = await service.ApproveCandidateForReviewAsync(student.Id, job.JobId, company.Id);

        Assert.Equal(emailSucceeds, approved);
        Assert.Equal(emailSucceeds ? ApplicationStatus.Company_Approved : ApplicationStatus.Student_Accepted, application.Status);
        Assert.Equal(1, email.SendCount);
        Assert.Equal("student@example.edu", email.Recipient);

        if (emailSucceeds)
        {
            Assert.False(await service.ApproveCandidateForReviewAsync(student.Id, job.JobId, company.Id));
            Assert.Equal(1, email.SendCount);
        }
    }

    private sealed class RecordingEmailService : IEmailService
    {
        public bool Succeeds { get; init; }
        public int SendCount { get; private set; }
        public string? Recipient { get; private set; }

        public Task<bool> SendCompanyShortlistApprovedAsync(string toEmail, string studentName, string companyName, string jobTitle, CancellationToken cancellationToken = default)
        {
            SendCount++;
            Recipient = toEmail;
            return Task.FromResult(Succeeds);
        }

        public Task<bool> SendAccountDecisionAsync(string recipient, string displayName, bool approved, CancellationToken cancellationToken = default) => throw new NotImplementedException();
        public Task<bool> SendInterviewScheduledAsync(string toEmail, string studentName, string companyName, string jobTitle, DateTime interviewDate, TimeSpan interviewTime, string? meetingLink, CancellationToken cancellationToken = default) => throw new NotImplementedException();
        public Task<bool> SendCandidateRejectedAsync(string toEmail, string studentName, string companyName, string jobTitle, string reason, CancellationToken cancellationToken = default) => throw new NotImplementedException();
    }
}
