using System;
using System.Collections.Generic;

namespace backend_dotnet.DTOs;

public class CompanyStatsDto
{
    public int ActiveJobDrives { get; set; }
    public int PrescreenedStudents { get; set; }
    public int InterviewsScheduled { get; set; }
    public int PartnerUniversityReach { get; set; }
}

public class CompanyActiveJobDto
{
    public Guid JobId { get; set; }
    public string JobTitle { get; set; } = string.Empty;
    public string TargetDomain { get; set; } = string.Empty;
    public string JobDescriptionSummary { get; set; } = string.Empty;
    public string[] InternshipType { get; set; } = Array.Empty<string>();
    public string LocationCity { get; set; } = string.Empty;
    public decimal MinimumGPA { get; set; }
    public int[] AllowedYearsOfStudy { get; set; } = Array.Empty<int>();
    public string[] MandatorySkills { get; set; } = Array.Empty<string>();
    public string[] NiceToHaveSkills { get; set; } = Array.Empty<string>();
    public string[] PreferredDegreePrograms { get; set; } = Array.Empty<string>();
    public bool StipendOffered { get; set; }
    public string? StipendAmountOrDetails { get; set; }
    public int DurationMonths { get; set; }
    public DateTime ApplicationDeadline { get; set; }
    public DateTime CreatedAt { get; set; }
    public int MatchesVerified { get; set; }
    public string Status { get; set; } = "Active • Accepting";
}

public class CompanyCandidateDto
{
    public string Id { get; set; } = string.Empty;
    public string Initials { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string University { get; set; } = string.Empty;
    public string Degree { get; set; } = string.Empty;
    public string Batch { get; set; } = string.Empty;
    public decimal Gpa { get; set; }
    public string MatchedOpening { get; set; } = string.Empty;
    public int MatchScore { get; set; }
    public string[] Competencies { get; set; } = Array.Empty<string>();
    public string Status { get; set; } = string.Empty;
    public string StatusColor { get; set; } = string.Empty;
    public string? CvPdfUrl { get; set; }
}

public class CompanyDashboardResponseDto
{
    public Guid CompanyId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string Industry { get; set; } = string.Empty;
    public string ContactPersonName { get; set; } = string.Empty;
    public string ContactPersonEmail { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string OrgCode { get; set; } = string.Empty;
    public CompanyStatsDto Stats { get; set; } = new();
    public List<CompanyActiveJobDto> ActiveJobs { get; set; } = new();
    public List<CompanyCandidateDto> ShortlistedCandidates { get; set; } = new();
}
