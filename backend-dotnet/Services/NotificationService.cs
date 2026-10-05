using backend_dotnet.Data;
using backend_dotnet.Models;

namespace backend_dotnet.Services;

public sealed class NotificationService(AppDbContext context) : INotificationService
{
    public void Add(Guid userId, string type, string title, string message, string destination, Guid? relatedEntityId = null)
    {
        context.Notifications.Add(new StudentNotification
        {
            UserId = userId,
            Type = type,
            Title = title,
            Message = message,
            Destination = destination,
            RelatedEntityId = relatedEntityId,
        });
    }

    public void AddIfMissing(Guid userId, string type, string title, string message, string destination, Guid? relatedEntityId = null)
    {
        if (context.Notifications.Any(item => item.UserId == userId && item.Type == type)) return;
        Add(userId, type, title, message, destination, relatedEntityId);
    }

    public void Clear(Guid userId, string type)
    {
        var existing = context.Notifications.Where(item => item.UserId == userId && item.Type == type);
        context.Notifications.RemoveRange(existing);
    }
}
