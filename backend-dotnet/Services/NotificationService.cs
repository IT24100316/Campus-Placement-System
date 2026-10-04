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
}
