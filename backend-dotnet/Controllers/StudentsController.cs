using backend_dotnet.Data;
using backend_dotnet.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudentsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IDocumentStorageService _storage;

    public StudentsController(AppDbContext context, IDocumentStorageService storage)
    {
        _context = context;
        _storage = storage;
    }

    /// <summary>Uploads or replaces a student's CV PDF for Agent 4 validation.</summary>
    [HttpPost("upload-cv")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadCv([FromForm] Guid studentId, IFormFile file, CancellationToken cancellationToken)
    {
        if (!string.Equals(file.ContentType, "application/pdf", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { message = "CV must be a PDF document." });
        var profile = await _context.StudentProfiles.FirstOrDefaultAsync(p => p.UserId == studentId, cancellationToken);
        if (profile is null) return NotFound(new { message = "Student profile not found." });
        try
        {
            var document = await _storage.UploadAsync(file, $"student-cvs/{studentId:N}", cancellationToken);
            profile.CvPdfUrl = document.StorageKey;
            await _context.SaveChangesAsync(cancellationToken);
            return Ok(new { storageKey = document.StorageKey, fileName = document.FileName });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
