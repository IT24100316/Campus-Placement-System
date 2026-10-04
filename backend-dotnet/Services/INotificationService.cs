namespace backend_dotnet.Services;

public interface INotificationService
{
    void Add(Guid userId, string type, string title, string message, string destination, Guid? relatedEntityId = null);
    void AddIfMissing(Guid userId, string type, string title, string message, string destination, Guid? relatedEntityId = null);
    void Clear(Guid userId, string type);
}
