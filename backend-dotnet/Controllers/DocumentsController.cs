using backend_dotnet.Services;
using Microsoft.AspNetCore.Mvc;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DocumentsController : ControllerBase
{
    private readonly IDocumentStorageService _storage;

    public DocumentsController(IDocumentStorageService storage) => _storage = storage;

    /// <summary>Uploads a private employer verification document.</summary>
    [HttpPost("business-registration")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadBusinessRegistration(IFormFile file, CancellationToken cancellationToken)
    {
        try
        {
            var document = await _storage.UploadAsync(file, "business-registration", cancellationToken);
            return Ok(new { storageKey = document.StorageKey, fileName = document.FileName });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Streams a private verification document through the API.</summary>
    [HttpGet("view")]
    public async Task<IActionResult> View([FromQuery] string key, CancellationToken cancellationToken)
    {
        var document = await _storage.OpenReadAsync(key, cancellationToken);
        return document is null
            ? NotFound(new { message = "Document not found." })
            : File(document.Value.Content, document.Value.ContentType, document.Value.FileName, enableRangeProcessing: true);
    }
}
