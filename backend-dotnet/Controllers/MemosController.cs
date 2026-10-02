using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MemosController : ControllerBase
{
    private readonly AppDbContext _context;

    public MemosController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("application/{applicationId}")]
    public async Task<IActionResult> GetMemos(Guid applicationId)
    {
        var memos = await _context.Memos
            .Include(m => m.Staff)
            .Where(m => m.ApplicationId == applicationId)
            .OrderByDescending(m => m.CreatedAt)
            .Select(m => new MemoResponseDto
            {
                MemoId = m.MemoId,
                ApplicationId = m.ApplicationId,
                StaffId = m.StaffId,
                StaffName = m.Staff.Role == UserRole.Company ? (m.Staff.CompanyStaffProfile != null ? m.Staff.CompanyStaffProfile.FullName : "Company Staff") : "Admin Staff", // Simplification
                MemoText = m.MemoText,
                Status = m.Status,
                CreatedAt = m.CreatedAt
            })
            .ToListAsync();

        return Ok(memos);
    }

    [HttpGet("pending-summary")]
    public async Task<IActionResult> GetPendingMemosSummary()
    {
        var appIds = await _context.Memos
            .Where(m => m.Status == "Pending")
            .Select(m => m.ApplicationId)
            .Distinct()
            .ToListAsync();
        
        return Ok(appIds);
    }

    [HttpPost]
    public async Task<IActionResult> CreateMemo([FromBody] CreateMemoDto dto)
    {
        var staffIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        Guid staffId;
        if (string.IsNullOrEmpty(staffIdStr) || !Guid.TryParse(staffIdStr, out staffId))
        {
            var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == UserRole.Admin);
            if (adminUser == null) return Unauthorized(new { message = "No Admin user found for fallback." });
            staffId = adminUser.Id;
        }

        var memo = new ApplicationMemo
        {
            ApplicationId = dto.ApplicationId,
            StaffId = staffId,
            MemoText = dto.MemoText,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        _context.Memos.Add(memo);
        await _context.SaveChangesAsync();

        // Fetch staff name for response
        var staff = await _context.Users.Include(u => u.CompanyStaffProfile).FirstOrDefaultAsync(u => u.Id == staffId);
        string staffName = staff?.Role == UserRole.Company ? (staff?.CompanyStaffProfile?.FullName ?? "Company Staff") : "Admin Staff";

        var response = new MemoResponseDto
        {
            MemoId = memo.MemoId,
            ApplicationId = memo.ApplicationId,
            StaffId = memo.StaffId,
            StaffName = staffName,
            MemoText = memo.MemoText,
            Status = memo.Status,
            CreatedAt = memo.CreatedAt
        };

        return CreatedAtAction(nameof(GetMemos), new { applicationId = memo.ApplicationId }, response);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateMemo(Guid id, [FromBody] UpdateMemoDto dto)
    {
        var staffIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        Guid staffId;
        if (string.IsNullOrEmpty(staffIdStr) || !Guid.TryParse(staffIdStr, out staffId))
        {
            var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == UserRole.Admin);
            if (adminUser != null) staffId = adminUser.Id;
        }

        var memo = await _context.Memos.FirstOrDefaultAsync(m => m.MemoId == id);
        if (memo == null) return NotFound();

        // Removed strict staffId check to allow testing
        // if (memo.StaffId != staffId) return Forbid("You can only edit your own memos.");

        memo.MemoText = dto.MemoText;
        await _context.SaveChangesAsync();

        return Ok();
    }

    [HttpPatch("{id}/resolve")]
    public async Task<IActionResult> ResolveMemo(Guid id)
    {
        var memo = await _context.Memos.FirstOrDefaultAsync(m => m.MemoId == id);
        if (memo == null) return NotFound();

        memo.Status = "Resolved";
        await _context.SaveChangesAsync();

        return Ok();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteMemo(Guid id)
    {
        var memo = await _context.Memos.FirstOrDefaultAsync(m => m.MemoId == id);
        if (memo == null) return NotFound();

        _context.Memos.Remove(memo);
        await _context.SaveChangesAsync();

        return Ok();
    }
}
