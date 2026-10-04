using System.Security.Claims;
using backend_dotnet.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Student")]
public class NotificationsController(AppDbContext context) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetMine(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var notifications = await context.Notifications
            .AsNoTracking()
            .Where(item => item.UserId == userId)
            .OrderByDescending(item => item.CreatedAt)
            .Take(50)
            .Select(item => new
            {
                id = item.Id,
                type = item.Type,
                title = item.Title,
                message = item.Message,
                destination = item.Destination,
                relatedEntityId = item.RelatedEntityId,
                isRead = item.IsRead,
                createdAt = item.CreatedAt,
            })
            .ToListAsync(cancellationToken);
        return Ok(notifications);
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var unreadCount = await context.Notifications.CountAsync(
            item => item.UserId == userId && !item.IsRead,
            cancellationToken);
        return Ok(new { unreadCount });
    }

    [HttpPost("{id:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid id, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var notification = await context.Notifications
            .SingleOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);
        if (notification is null) return NotFound();
        notification.IsRead = true;
        await context.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpPost("mark-all-read")]
    public async Task<IActionResult> MarkAllRead(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        await context.Notifications
            .Where(item => item.UserId == userId && !item.IsRead)
            .ExecuteUpdateAsync(setters => setters.SetProperty(item => item.IsRead, true), cancellationToken);
        return NoContent();
    }

    private bool TryGetUserId(out Guid userId) => Guid.TryParse(
        User.FindFirstValue(ClaimTypes.NameIdentifier), out userId);
}
