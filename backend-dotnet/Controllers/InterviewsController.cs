using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Services;
using backend_dotnet.Models;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class InterviewsController : ControllerBase
{
    private readonly IApplicationService _applicationService;
    private readonly AppDbContext _context;

    public InterviewsController(IApplicationService applicationService, AppDbContext context)
    {
        _applicationService = applicationService;
        _context = context;
    }

    public sealed record ApproveShortlistRequest(Guid StudentId, Guid JobId);

    [HttpPost("approve-shortlist")]
    [Authorize(Roles = "Company")]
    public async Task<IActionResult> ApproveShortlist([FromBody] ApproveShortlistRequest request, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            return Unauthorized();

        var companyId = await _context.Users
            .Where(u => u.Id == userId)
            .Select(u => u.CompanyStaffProfile != null ? u.CompanyStaffProfile.CompanyId : u.CompanyProfile != null ? u.CompanyProfile.UserId : Guid.Empty)
            .FirstOrDefaultAsync(cancellationToken);
        if (companyId == Guid.Empty) return Forbid();

        var approved = await _applicationService.ApproveCandidateForReviewAsync(request.StudentId, request.JobId, companyId, cancellationToken);
        if (!approved) return Conflict(new { message = "The candidate cannot be approved or the email could not be sent." });
        return Ok(new { message = "Candidate approved for review and student notified." });
    }

    [HttpPost("schedule")]
    public async Task<IActionResult> ScheduleInterview([FromBody] ScheduleInterviewRequestDto request)
    {
        var success = await _applicationService.ScheduleInterviewAsync(request);

        if (!success)
        {
            return StatusCode(500, new { message = "Failed to dispatch email or schedule the interview." });
        }

        return Ok(new { message = "Interview confirmed and calendar invitation dispatched successfully." });
    }

    [HttpPost("reject")]
    public async Task<IActionResult> RejectCandidate([FromBody] RejectCandidateRequestDto request)
    {
        var success = await _applicationService.RejectCandidateAsync(request);

        if (!success)
        {
            return StatusCode(500, new { message = "Failed to dispatch email or reject the candidate." });
        }

        return Ok(new { message = "Candidate rejected successfully and notified." });
    }
}
