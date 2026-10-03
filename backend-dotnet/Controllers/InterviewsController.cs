using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend_dotnet.Data;
using backend_dotnet.DTOs;
using backend_dotnet.Services;
using backend_dotnet.Models;
using Microsoft.Extensions.Logging;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class InterviewsController : ControllerBase
{
    private readonly IApplicationService _applicationService;

    public InterviewsController(IApplicationService applicationService)
    {
        _applicationService = applicationService;
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
