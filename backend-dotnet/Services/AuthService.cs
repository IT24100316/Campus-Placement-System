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

    public AuthService(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Authenticates user and evaluates multi-role clearance and status lifecycle
    /// </summary>
    public async Task<AuthLoginResultDto?> LoginAsync(LoginDto dto)
    {
        var normalizedEmail = dto.Email.Trim().ToLower();

        var user = await _context.Users
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
        var detailedRole = user.Role == UserRole.Admin
            ? "Admin"
            : (isStaff ? "CompanyStaff" : (isHr ? "CompanyHR" : user.Role.ToString()));

        var companyName = isStaff
            ? user.CompanyStaffProfile?.Company?.CompanyName
            : user.CompanyProfile?.CompanyName;

        var fullName = isStaff
            ? user.CompanyStaffProfile?.FullName
            : user.CompanyProfile?.ContactPersonName;

        // Pending approval check
        if (user.Status == AccountStatus.Pending)
        {
            return new AuthLoginResultDto
            {
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
        return new AuthLoginResultDto
        {
            Success = true,
            Email = user.Email,
            Role = detailedRole,
            Status = user.Status.ToString(),
            CompanyName = companyName,
            FullName = fullName,
            StaffId = user.CompanyStaffProfile?.StaffId,
            JobPosition = user.CompanyStaffProfile?.JobPosition,
            Message = "Authentication successful."
        };
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

    /// <summary>
    /// Retrieves list of recognized employers for staff registration dropdowns
    /// </summary>
    public async Task<IEnumerable<ApprovedCompanyDto>> GetCompaniesAsync()
    {
        return await _context.CompanyProfiles
            .AsNoTracking()
            .Select(c => new ApprovedCompanyDto
            {
                Id = c.UserId,
                Name = c.CompanyName,
                Industry = c.Industry
            })
            .ToListAsync();
    }
}
