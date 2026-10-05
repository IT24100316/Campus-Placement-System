using Microsoft.EntityFrameworkCore;
using backend_dotnet.Configuration;
using backend_dotnet.Data;
using backend_dotnet.Services;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using Polly;
using Polly.Extensions.Http;

var builder = WebApplication.CreateBuilder(args);

// 1. Connection String
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString, npgsqlOptions =>
        npgsqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorCodesToAdd: null)));

// 2. Controllers
builder.Services.AddControllers();
builder.Services.AddScoped<IDocumentStorageService, DocumentStorageService>();

// Phase 2: Register SendGrid Email Service with Polly Exponential Backoff Retry Policy
builder.Services.AddHttpClient<IEmailService, BrevoEmailService>()
    .AddTransientHttpErrorPolicy(policyBuilder =>
        policyBuilder.WaitAndRetryAsync(3, retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt))));

// 2.1 CV storage configuration
builder.Services.Configure<CvStorageOptions>(
    builder.Configuration.GetSection(CvStorageOptions.SectionName));

// 2.5 Register placement application matching services for Dependency Injection
builder.Services.AddScoped<IApplicationService, ApplicationService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<ICompanyService, CompanyService>();
builder.Services.AddScoped<ICvFileValidationService, CvFileValidationService>();
builder.Services.AddHttpClient<ICvStorageService, SupabaseCvStorageService>();
builder.Services.AddScoped<IJobService, JobService>();
builder.Services.AddScoped<INotificationService, NotificationService>();

// 2.7 Register Background Services
// builder.Services.AddHostedService<EvaluationTriggerService>();
builder.Services.AddHostedService<AutoDeclineBackgroundService>();

// 3. CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.SetIsOriginAllowed(origin => true) // Allow Flutter web and React
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// JWT authentication. Authorization policies used by other features can consume
// the authenticated identity through HttpContext.User without coupling to auth code.
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        var jwtKey = builder.Configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("JWT signing key is not configured.");

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.Zero
        };
    });

// 4. Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "CampusAI Placement API",
        Version = "v1",
        Description = "Account verification, document storage, AI validation approval gates, and interview scheduling."
    });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Enter the JWT returned by the login endpoint."
    });
    options.OperationFilter<AuthorizeOperationFilter>();
    var xmlPath = Path.Combine(AppContext.BaseDirectory, "backend-dotnet.xml");
    if (File.Exists(xmlPath)) options.IncludeXmlComments(xmlPath);
});

var app = builder.Build();

// 5. Seed Single Inbuilt Admin Account and Default Approved Companies on Startup
if (builder.Configuration.GetValue("SeedAdminOnStartup", true))
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var hasher = new PasswordHasher<User>();

    // Seed or Update Admin
    var adminEmail = builder.Configuration["AdminSettings:Email"];
    var adminPassword = builder.Configuration["AdminSettings:Password"];
    
    if (string.IsNullOrEmpty(adminEmail) || string.IsNullOrEmpty(adminPassword))
    {
        throw new InvalidOperationException("Admin credentials must be provided in configuration (AdminSettings:Email and AdminSettings:Password) to seed the admin account.");
    }

    var existingAdmin = dbContext.Users.FirstOrDefault(u => u.Role == UserRole.Admin);
    if (existingAdmin == null)
    {
        var adminUser = new User
        {
            Id = Guid.NewGuid(),
            Email = adminEmail,
            Role = UserRole.Admin,
            Status = AccountStatus.Approved,
            CreatedAt = DateTime.UtcNow
        };
        adminUser.PasswordHash = hasher.HashPassword(adminUser, adminPassword);
        dbContext.Users.Add(adminUser);
        dbContext.SaveChanges();
    }
    else
    {
        var result = hasher.VerifyHashedPassword(existingAdmin, existingAdmin.PasswordHash, adminPassword);
        if (result == PasswordVerificationResult.Failed)
        {
            existingAdmin.Email = adminEmail;
            existingAdmin.PasswordHash = hasher.HashPassword(existingAdmin, adminPassword);
            dbContext.SaveChanges();
        }
    }

    // 5b. Seed Controlled Computing Target Domains & Realistic Internship Titles (Idempotent)
    // Removed hardcoded companies and demo students for security
    await JobReferenceSeeder.SeedAsync(dbContext);
}

// Configure HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Middleware 
app.UseCors("AllowFrontend");

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
