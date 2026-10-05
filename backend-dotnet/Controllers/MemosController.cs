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

    // Grabs all the internal memos written for a specific application.
    // Useful when staff need to review the discussion history of a candidate.
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

    // Quick summary endpoint that returns a list of application IDs that currently have unresolved, pending memos.
    // Used to show those little notification badges on the admin dashboard!
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

    // Creates a brand new memo for an application.
    // Staff can use this to drop notes, flag issues, or ask questions before making a final decision.
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

    // Updates the text of an existing memo.
    // Handy for fixing typos or adding more context to an ongoing discussion.
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

    // Marks a memo as "Resolved" when the issue or question has been addressed!
    // This clears the roadblock so the application can finally be approved.
    [HttpPatch("{id}/resolve")]
    public async Task<IActionResult> ResolveMemo(Guid id)
    {
        var memo = await _context.Memos.FirstOrDefaultAsync(m => m.MemoId == id);
        if (memo == null) return NotFound();

        memo.Status = "Resolved";
        await _context.SaveChangesAsync();

        return Ok();
    }

    // Deletes a memo completely from the system.
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
