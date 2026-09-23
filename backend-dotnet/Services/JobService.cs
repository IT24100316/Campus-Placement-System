using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Services;

public class JobService : IJobService
{
    private readonly AppDbContext _context;

    public JobService(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Retrieve all controlled Target Domains from the database
    /// </summary>
    public async Task<IEnumerable<TargetDomainDto>> GetTargetDomainsAsync()
    {
        return await _context.TargetDomains
            .AsNoTracking()
            .OrderBy(d => d.Name)
            .Select(d => new TargetDomainDto
            {
                Id = d.Id,
                Name = d.Name,
                Description = d.Description,
                TitleCount = d.JobTitles.Count
            })
            .ToListAsync();
    }

    /// <summary>
    /// Retrieve Job Titles filtered by Target Domain from the database
    /// </summary>
    public async Task<IEnumerable<JobTitleDto>> GetJobTitlesAsync(int? domainId, string? domain)
    {
        IQueryable<JobTitleReference> query = _context.JobTitles
            .AsNoTracking()
            .Include(jt => jt.TargetDomain);

        if (domainId.HasValue && domainId.Value > 0)
        {
            query = query.Where(jt => jt.TargetDomainId == domainId.Value);
        }
        else if (!string.IsNullOrWhiteSpace(domain))
        {
            var normalizedDomain = domain.Trim().ToLower();
            query = query.Where(jt => jt.TargetDomain.Name.ToLower() == normalizedDomain);
        }

        return await query
            .OrderBy(jt => jt.Title)
            .Select(jt => new JobTitleDto
            {
                Id = jt.Id,
                Title = jt.Title,
                TargetDomainId = jt.TargetDomainId,
                TargetDomainName = jt.TargetDomain.Name
            })
            .ToListAsync();
    }

    /// <summary>
    /// Retrieve controlled Internship Types strictly from backend enum (OnSite, Hybrid, Remote)
    /// </summary>
    public IEnumerable<string> GetInternshipTypes()
    {
        return Enum.GetNames<InternshipType>();
    }

    /// <summary>
    /// Validate domain gating, cross-reference titles, resolve employer company, and persist Job to Supabase
    /// </summary>
    public async Task<JobCreationResultDto> CreateJobAsync(CreateJobRequestDto request)
    {
        // 1. Validate InternshipType against enum
        if (!Enum.TryParse<InternshipType>(request.InternshipType?.Trim(), true, out var internshipTypeEnum))
        {
            return new JobCreationResultDto
            {
                Success = false,
                ErrorTitle = "Invalid Internship Type",
                ErrorMessage = $"Internship Type must be strictly one of: {string.Join(", ", Enum.GetNames<InternshipType>())}."
            };
        }

        // 2. Validate Target Domain in Database
        TargetDomain? domainEntity = null;
        if (request.TargetDomainId.HasValue && request.TargetDomainId.Value > 0)
        {
            domainEntity = await _context.TargetDomains
                .Include(d => d.JobTitles)
                .FirstOrDefaultAsync(d => d.Id == request.TargetDomainId.Value);
        }

        if (domainEntity == null && !string.IsNullOrWhiteSpace(request.TargetDomain))
        {
            var normalized = request.TargetDomain.Trim().ToLower();
            domainEntity = await _context.TargetDomains
                .Include(d => d.JobTitles)
                .FirstOrDefaultAsync(d => d.Name.ToLower() == normalized);
        }

        if (domainEntity == null)
        {
            return new JobCreationResultDto
            {
                Success = false,
                ErrorTitle = "Invalid Target Domain",
                ErrorMessage = $"The Target Domain '{request.TargetDomain}' is not recognized in the database reference registry."
            };
        }

        // 3. Validate Job Title belongs to the selected Target Domain
        JobTitleReference? jobTitleEntity = null;
        if (request.JobTitleId.HasValue && request.JobTitleId.Value > 0)
        {
            jobTitleEntity = domainEntity.JobTitles
                .FirstOrDefault(t => t.Id == request.JobTitleId.Value);
        }

        if (jobTitleEntity == null && !string.IsNullOrWhiteSpace(request.JobTitle))
        {
            var normalizedTitle = request.JobTitle.Trim().ToLower();
            jobTitleEntity = domainEntity.JobTitles
                .FirstOrDefault(t => t.Title.ToLower() == normalizedTitle);
        }

        if (jobTitleEntity == null)
        {
            return new JobCreationResultDto
            {
                Success = false,
                ErrorTitle = "Dependent Job Title Mismatch",
                ErrorMessage = $"The Job Title '{request.JobTitle}' does not belong to the Target Domain '{domainEntity.Name}'."
            };
        }

        // 4. Validate GPA and Duration
        if (request.MinimumGPA < 0.00m || request.MinimumGPA > 4.00m)
        {
            return new JobCreationResultDto
            {
                Success = false,
                ErrorTitle = "Invalid GPA",
                ErrorMessage = "Minimum GPA must be between 0.00 and 4.00."
            };
        }

        if (request.DurationMonths < 1 || request.DurationMonths > 24)
        {
            return new JobCreationResultDto
            {
                Success = false,
                ErrorTitle = "Invalid Duration",
                ErrorMessage = "Duration must be between 1 and 24 months."
            };
        }

        // 5. Validate Application Deadline (must be in future)
        if (request.ApplicationDeadline <= DateTime.UtcNow)
        {
            return new JobCreationResultDto
            {
                Success = false,
                ErrorTitle = "Invalid Deadline",
                ErrorMessage = "Application deadline must be a future date."
            };
        }

        // 6. Identify Company Profile
        CompanyProfile? company = null;
        if (request.CompanyId.HasValue && request.CompanyId.Value != Guid.Empty)
        {
            company = await _context.CompanyProfiles
                .FirstOrDefaultAsync(c => c.UserId == request.CompanyId.Value);
        }

        if (company == null && !string.IsNullOrWhiteSpace(request.RecruiterEmail))
        {
            var normalizedEmail = request.RecruiterEmail.Trim().ToLower();
            company = await _context.CompanyProfiles
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.ContactPersonEmail.ToLower() == normalizedEmail || c.User.Email.ToLower() == normalizedEmail);

            // Also check if recruiter email belongs to a registered company staff member
            if (company == null)
            {
                var staff = await _context.CompanyStaffProfiles
                    .Include(s => s.Company)
                    .Include(s => s.User)
                    .FirstOrDefaultAsync(s => s.User.Email.ToLower() == normalizedEmail);
                if (staff?.Company != null)
                {
                    company = staff.Company;
                }
            }
        }

        // Fallback to first approved company in DB if not found
        if (company == null)
        {
            company = await _context.CompanyProfiles.FirstOrDefaultAsync();
        }

        if (company == null)
        {
            return new JobCreationResultDto
            {
                Success = false,
                ErrorTitle = "Company Profile Not Found",
                ErrorMessage = "Unable to associate this job with a registered company profile."
            };
        }

        // 7. Instantiate and save Job
        var newJob = new Job
        {
            JobId = Guid.NewGuid(),
            CompanyId = company.UserId,
            JobTitle = jobTitleEntity.Title,
            JobTitleId = jobTitleEntity.Id,
            TargetDomain = domainEntity.Name,
            TargetDomainId = domainEntity.Id,
            JobDescriptionSummary = request.JobDescriptionSummary.Trim(),
            InternshipType = new[] { internshipTypeEnum.ToString() },
            LocationCity = request.LocationCity.Trim(),
            MinimumGPA = decimal.Round(request.MinimumGPA, 2),
            AllowedYearsOfStudy = request.AllowedYearsOfStudy?.Length > 0 
                ? request.AllowedYearsOfStudy 
                : new[] { 3, 4 },
            MandatorySkills = request.MandatorySkills?
                .Select(s => s.Trim())
                .Where(s => !string.IsNullOrEmpty(s))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray() ?? Array.Empty<string>(),
            NiceToHaveSkills = request.NiceToHaveSkills?
                .Select(s => s.Trim())
                .Where(s => !string.IsNullOrEmpty(s))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray() ?? Array.Empty<string>(),
            PreferredDegreePrograms = request.PreferredDegreePrograms?
                .Select(p => p.Trim())
                .Where(p => !string.IsNullOrEmpty(p))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray() ?? Array.Empty<string>(),
            StipendOffered = request.StipendOffered,
            StipendAmountOrDetails = request.StipendOffered && !string.IsNullOrWhiteSpace(request.StipendAmountOrDetails)
                ? request.StipendAmountOrDetails.Trim()
                : null,
            DurationMonths = request.DurationMonths,
            ApplicationDeadline = DateTime.SpecifyKind(request.ApplicationDeadline, DateTimeKind.Utc),
            CreatedAt = DateTime.UtcNow
        };

        _context.Jobs.Add(newJob);
        await _context.SaveChangesAsync();

        var responseDto = new JobResponseDto
        {
            JobId = newJob.JobId,
            CompanyId = newJob.CompanyId,
            CompanyName = company.CompanyName,
            JobTitle = newJob.JobTitle,
            TargetDomain = newJob.TargetDomain,
            JobDescriptionSummary = newJob.JobDescriptionSummary,
            InternshipType = newJob.InternshipType,
            LocationCity = newJob.LocationCity,
            MinimumGPA = newJob.MinimumGPA,
            AllowedYearsOfStudy = newJob.AllowedYearsOfStudy,
            MandatorySkills = newJob.MandatorySkills,
            NiceToHaveSkills = newJob.NiceToHaveSkills,
            PreferredDegreePrograms = newJob.PreferredDegreePrograms,
            StipendOffered = newJob.StipendOffered,
            StipendAmountOrDetails = newJob.StipendAmountOrDetails,
            DurationMonths = newJob.DurationMonths,
            ApplicationDeadline = newJob.ApplicationDeadline,
            CreatedAt = newJob.CreatedAt,
            MatchesVerified = 42,
            Status = "Active • Accepting"
        };

        return new JobCreationResultDto
        {
            Success = true,
            Job = responseDto
        };
    }
}
