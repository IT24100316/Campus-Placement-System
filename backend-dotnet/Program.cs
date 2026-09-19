using Microsoft.EntityFrameworkCore;
using backend_dotnet.Data;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Identity;

var builder = WebApplication.CreateBuilder(args);

// 1. Connection String
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

// 2. Controllers
builder.Services.AddControllers();

// 3. CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// 4. Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 5. Seed Single Inbuilt Admin Account on Startup (Option A)
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (!dbContext.Users.Any(u => u.Role == UserRole.Admin))
    {
        var adminUser = new User
        {
            Id = Guid.NewGuid(),
            Email = "admin@campusai.edu",
            Role = UserRole.Admin,
            Status = AccountStatus.Approved,
            CreatedAt = DateTime.UtcNow
        };
        var hasher = new PasswordHasher<User>();
        adminUser.PasswordHash = hasher.HashPassword(adminUser, "Admin@2025");
        dbContext.Users.Add(adminUser);
        dbContext.SaveChanges();
    }
}

// Configure HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Middleware 
app.UseCors("AllowFrontend");

app.UseAuthorization();

app.MapControllers();

app.Run();
