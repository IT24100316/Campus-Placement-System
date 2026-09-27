using backend_dotnet.Data;
using backend_dotnet.Models;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace backend_dotnet.Tests;

public class ApplicationUniqueIndexTests
{
    [Fact]
    public void Application_HasUniqueStudentJobIndexInThatOrder()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        using var context = new AppDbContext(options);

        var entity = context.Model.FindEntityType(typeof(Application));
        Assert.NotNull(entity);

        var index = Assert.Single(entity.GetIndexes(), index =>
            index.Properties.Select(property => property.Name)
                .SequenceEqual(new[] { nameof(Application.StudentId), nameof(Application.JobId) }));
        Assert.True(index.IsUnique);
    }
}
