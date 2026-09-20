# Backend Models Documentation

This directory contains all the Entity Framework Core models used in the Campus Placement System backend.

## Application

| Property | Type | Description |
|----------|------|-------------|
| Application | class | |
| AppId | Guid | |
| StudentId | Guid | |
| JobId | Guid | |
| MatchScore | int | |
| SummaryReport | string | |
| Status | ApplicationStatus | |
| InterviewDate | DateTime? | |
| InterviewTime | TimeSpan? | |
| CompanyMessage | string? | |
| Student | User | |
| Job | Job | |

## CompanyProfile

| Property | Type | Description |
|----------|------|-------------|
| CompanyProfile | class | |
| UserId | Guid | |
| CompanyName | string | |
| Industry | string | |
| ContactPersonName | string | |
| ContactPersonEmail | string | |
| Phone | string | |
| BusinessRegistrationDocumentUrl | string | |
| User | User | |
| Jobs | ICollection&lt;Job&gt; | |
| StaffMembers | ICollection&lt;CompanyStaffProfile&gt; | |

## CompanyStaffProfile

| Property | Type | Description |
|----------|------|-------------|
| CompanyStaffProfile | class | |
| UserId | Guid | |
| CompanyId | Guid | |
| FullName | string | |
| StaffId | string | |
| JobPosition | string | |
| User | User | |
| Company | CompanyProfile | |

## UserRole

| Value | Description |
|-------|-------------|
| Student | |
| Company | |
| Admin | |

## InternshipType

| Value | Description |
|-------|-------------|
| OnSite | |
| Hybrid | |
| Remote | |

## Job

| Property | Type | Description |
|----------|------|-------------|
| Job | class | |
| JobId | Guid | |
| CompanyId | Guid | |
| JobTitle | string | |
| TargetDomain | string | |
| JobDescriptionSummary | string | |
| InternshipType | string[] | |
| LocationCity | string | |
| MinimumGPA | decimal | |
| AllowedYearsOfStudy | int[] | |
| MandatorySkills | string[] | |
| NiceToHaveSkills | string[] | |
| PreferredDegreePrograms | string[] | |
| StipendOffered | bool | |
| StipendAmountOrDetails | string? | |
| DurationMonths | int | |
| ApplicationDeadline | DateTime | |
| CreatedAt | DateTime | |
| TargetDomainId | int? | |
| DomainReference | TargetDomain? | |
| JobTitleId | int? | |
| JobTitleReference | JobTitleReference? | |
| Company | CompanyProfile | |
| Applications | ICollection&lt;Application&gt; | |

## JobTitleReference

| Property | Type | Description |
|----------|------|-------------|
| JobTitleReference | class | |
| Id | int | |
| Title | string | |
| TargetDomainId | int | |
| TargetDomain | TargetDomain | |
| Jobs | ICollection&lt;Job&gt; | |

## StudentProfile

| Property | Type | Description |
|----------|------|-------------|
| StudentProfile | class | |
| UserId | Guid | |
| FullName | string | |
| Phone | string | |
| CampusIdPhotoUrl | string | |
| PortfolioUrl | string? | |
| UniversityName | string | |
| AcademicStatus | string | |
| DegreeProgram | string | |
| CurrentYearOfStudy | int | |
| GPA | decimal | |
| ExpectedGraduationDate | DateTime? | |
| DesiredJobTitle | string | |
| PrimaryDomain | string | |
| CareerObjectivesSummary | string | |
| Skills | string[] | |
| ToolsAndTechnologies | string[] | |
| InternshipType | string[] | |
| LectureScheduleType | string | |
| PreferredLocations | string[] | |
| CvPdfUrl | string | |
| User | User | |

## TargetDomain

| Property | Type | Description |
|----------|------|-------------|
| TargetDomain | class | |
| Id | int | |
| Name | string | |
| Description | string? | |
| JobTitles | ICollection&lt;JobTitleReference&gt; | |
| Jobs | ICollection&lt;Job&gt; | |

## User

| Property | Type | Description |
|----------|------|-------------|
| User | class | |
| Id | Guid | |
| Email | string | |
| PasswordHash | string | |
| Role | UserRole | |
| Status | AccountStatus | |
| CreatedAt | DateTime | |
| StudentProfile | StudentProfile? | |
| CompanyProfile | CompanyProfile? | |
| CompanyStaffProfile | CompanyStaffProfile? | |
| Applications | ICollection&lt;Application&gt; | |

