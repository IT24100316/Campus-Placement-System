using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _context;
    private readonly PasswordHasher<User> _passwordHasher = new();
    private readonly IDocumentStorageService _documentStorage;
    private readonly IJwtService _jwtService;

    public AuthService(AppDbContext context, IDocumentStorageService documentStorage, IJwtService jwtService)
    {
        _context = context;
        _documentStorage = documentStorage;
        _jwtService = jwtService;
    }

    public async Task<AuthRegisterResultDto> RegisterAsync(
        RegisterRequestDto dto,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = dto.Email.Trim().ToLowerInvariant();

        if (dto.Role.Equals("CompanyHR", StringComparison.OrdinalIgnoreCase)
            || dto.Role.Equals("Company", StringComparison.OrdinalIgnoreCase))
        {
            if (string.IsNullOrWhiteSpace(dto.Phone)
                || string.IsNullOrWhiteSpace(dto.CompanyName)
                || string.IsNullOrWhiteSpace(dto.Industry))
            {
                throw new InvalidOperationException(
                    "Company registration requires phone, companyName, and industry.");
            }

            return await RegisterCompanyHrAsync(new RegisterCompanyHrDto
            {
                FullName = dto.FullName,
                Email = normalizedEmail,
                Password = dto.Password,
                Phone = dto.Phone,
                CompanyName = dto.CompanyName,
                Industry = dto.Industry,
                BusinessRegistrationDocumentUrl = dto.BusinessRegistrationDocumentUrl ?? string.Empty
            });
        }

        if (await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail, cancellationToken))
            throw new InvalidOperationException("Email is already registered in the system.");

        if (!Enum.TryParse<UserRole>(dto.Role, true, out var role) || role != UserRole.Student)
            throw new InvalidOperationException(
                "Registration supports Student or CompanyHR accounts. Staff accounts require the staff registration endpoint.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = normalizedEmail,
            Role = role,
            Status = AccountStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);

        user.StudentProfile = new StudentProfile
        {
            UserId = user.Id,
            FullName = dto.FullName.Trim(),
            AcademicStatus = "Pending verification"
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync(cancellationToken);

        return new AuthRegisterResultDto
        {
            Success = true,
            Message = "User registered successfully",
            UserId = user.Id,
            Status = user.Status.ToString()
        };
    }

    /// <summary>
    /// Authenticates user and evaluates multi-role clearance and status lifecycle
    /// </summary>
    public async Task<AuthLoginResultDto?> LoginAsync(LoginDto dto)
    {
        var normalizedEmail = dto.Email.Trim().ToLower();

        var user = await _context.Users
            .Include(u => u.StudentProfile)
            .Include(u => u.CompanyProfile)
            .Include(u => u.CompanyStaffProfile)
                .ThenInclude(sp => sp!.Company)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);

        if (user == null)
            return null;

        var verifyResult = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
        if (verifyResult == PasswordVerificationResult.Failed)
            return null;

        var isStaff = user.CompanyStaffProfile != null;
        var isHr = user.CompanyProfile != null;
        var detailedRole = GetDetailedRole(user);

        var companyName = isStaff
            ? user.CompanyStaffProfile?.Company?.CompanyName
            : user.CompanyProfile?.CompanyName;

        var fullName = isStaff
            ? user.CompanyStaffProfile?.FullName
            : user.CompanyProfile?.ContactPersonName ?? user.StudentProfile?.FullName;

        // Pending approval check
        if (user.Status == AccountStatus.Pending)
        {
            return new AuthLoginResultDto
            {
                UserId = user.Id,
                Success = false,
                IsPending = true,
                Message = "Your registration application is currently under administrative review.",
                Role = detailedRole,
                Status = user.Status.ToString(),
                Email = user.Email,
                CompanyName = companyName,
                FullName = fullName,
                StaffId = user.CompanyStaffProfile?.StaffId,
                JobPosition = user.CompanyStaffProfile?.JobPosition
            };
        }

        // Rejected account check
        if (user.Status == AccountStatus.Rejected)
        {
            return new AuthLoginResultDto
            {
                Success = false,
                IsRejected = true,
                Message = "Your account application has been declined by the administrator."
            };
        }

        // Approved active user
        var authUser = ToAuthUser(user);
        return new AuthLoginResultDto
        {
            UserId = user.Id,
            Success = true,
            Email = user.Email,
            Role = detailedRole,
            Status = user.Status.ToString(),
            CompanyName = companyName,
            FullName = fullName,
            StaffId = user.CompanyStaffProfile?.StaffId,
            JobPosition = user.CompanyStaffProfile?.JobPosition,
            Token = _jwtService.GenerateToken(user),
            User = authUser,
            Message = "Authentication successful."
        };
    }

    public async Task<AuthUserDto?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .AsNoTracking()
            .Include(u => u.StudentProfile)
            .Include(u => u.CompanyProfile)
            .Include(u => u.CompanyStaffProfile)
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

        return user == null ? null : ToAuthUser(user);
    }

    private static AuthUserDto ToAuthUser(User user)
    {
        var fullName = user.StudentProfile?.FullName
            ?? user.CompanyStaffProfile?.FullName
            ?? user.CompanyProfile?.ContactPersonName;

        return new AuthUserDto
        {
            Id = user.Id,
            FullName = fullName,
            Email = user.Email,
            Role = GetDetailedRole(user)
        };
    }

    private static string GetDetailedRole(User user)
    {
        if (user.Role == UserRole.Admin) return "Admin";
        if (user.CompanyStaffProfile != null) return "CompanyStaff";
        if (user.CompanyProfile != null) return "CompanyHR";
        return user.Role.ToString();
    }

    /// <summary>
    /// Registers a new Company HR account with pending administrator approval
    /// </summary>
    public async Task<AuthRegisterResultDto> RegisterCompanyHrAsync(RegisterCompanyHrDto dto)
    {
        var normalizedEmail = dto.Email.Trim().ToLower();

        var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail);
        if (emailExists)
            throw new InvalidOperationException("Email is already registered in the system.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = normalizedEmail,
            Role = UserRole.Company,
            Status = AccountStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);

        var companyProfile = new CompanyProfile
        {
            UserId = user.Id,
            CompanyName = dto.CompanyName.Trim(),
            Industry = dto.Industry.Trim(),
            ContactPersonName = dto.FullName.Trim(),
            ContactPersonEmail = normalizedEmail,
            Phone = dto.Phone.Trim(),
            BusinessRegistrationDocumentUrl = string.IsNullOrWhiteSpace(dto.BusinessRegistrationDocumentUrl)
                ? "sample_br_doc.pdf"
                : dto.BusinessRegistrationDocumentUrl
        };

        _context.Users.Add(user);
        _context.CompanyProfiles.Add(companyProfile);
        await _context.SaveChangesAsync();

        return new AuthRegisterResultDto
        {
            Success = true,
            Message = "Company HR registered successfully. Awaiting administrator approval.",
            UserId = user.Id,
            CompanyName = companyProfile.CompanyName,
            Status = user.Status.ToString()
        };
    }

    /// <summary>
    /// Registers a new Company Staff account linked to an existing employer company
    /// </summary>
    public async Task<AuthRegisterResultDto> RegisterCompanyStaffAsync(RegisterCompanyStaffDto dto)
    {
        var normalizedEmail = dto.Email.Trim().ToLower();

        var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail);
        if (emailExists)
            throw new InvalidOperationException("Email is already registered in the system.");

        var company = await _context.CompanyProfiles.FirstOrDefaultAsync(c => c.UserId == dto.CompanyId);
        if (company == null)
            throw new KeyNotFoundException("Selected employer company not found.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = normalizedEmail,
            Role = UserRole.Company,
            Status = AccountStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);

        var staffProfile = new CompanyStaffProfile
        {
            UserId = user.Id,
            CompanyId = company.UserId,
            FullName = dto.FullName.Trim(),
            StaffId = dto.StaffId.Trim(),
            JobPosition = dto.JobPosition.Trim()
        };

        _context.Users.Add(user);
        _context.CompanyStaffProfiles.Add(staffProfile);
        await _context.SaveChangesAsync();

        return new AuthRegisterResultDto
        {
            Success = true,
            Message = "Company Staff registered successfully. Awaiting administrator approval.",
            UserId = user.Id,
            CompanyName = company.CompanyName,
            Status = user.Status.ToString()
        };
    }

    public async Task<AuthRegisterResultDto> RegisterStudentAsync(RegisterStudentFormDto dto, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = dto.Email.Trim().ToLowerInvariant();
        if (await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail, cancellationToken))
            throw new InvalidOperationException("Email is already registered in the system.");

        var campusId = await _documentStorage.UploadAsync(dto.CampusIdPhoto, "campus-ids", cancellationToken);
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = normalizedEmail,
            Role = UserRole.Student,
            Status = AccountStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);
        var profile = new StudentProfile
        {
            UserId = user.Id,
            FullName = dto.FullName.Trim(),
            Phone = dto.Phone.Trim(),
            UniversityName = dto.UniversityName.Trim(),
            CampusIdPhotoUrl = campusId.StorageKey,
            AcademicStatus = "Pending verification"
        };
        _context.Users.Add(user);
        _context.StudentProfiles.Add(profile);
        await _context.SaveChangesAsync(cancellationToken);
        return new AuthRegisterResultDto
        {
            UserId = user.Id,
            Status = user.Status.ToString(),
            Message = "Student registered successfully. Awaiting campus ID verification."
        };
    }

    /// <summary>
    /// Retrieves list of recognized employers for staff registration dropdowns
    /// </summary>
    public async Task<IEnumerable<ApprovedCompanyDto>> GetCompaniesAsync()
    {
        return await _context.CompanyProfiles
            .AsNoTracking()
            .Where(c => c.User.Status == AccountStatus.Approved)
            .Select(c => new ApprovedCompanyDto
            {
                Id = c.UserId,
                Name = c.CompanyName,
                Industry = c.Industry
            })
            .ToListAsync();
    }
}
