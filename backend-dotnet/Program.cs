using Microsoft.EntityFrameworkCore;
using backend_dotnet.Configuration;
using backend_dotnet.Data;
using backend_dotnet.Services;
using backend_dotnet.Models;
using Microsoft.AspNetCore.Identity;

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

// 2.1 CV storage configuration
builder.Services.Configure<CvStorageOptions>(
    builder.Configuration.GetSection(CvStorageOptions.SectionName));

// 2.5 Register placement application matching services for Dependency Injection
builder.Services.AddScoped<IApplicationService, ApplicationService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICompanyService, CompanyService>();
builder.Services.AddScoped<ICvFileValidationService, CvFileValidationService>();
builder.Services.AddScoped<IJobService, JobService>();

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

// 5. Seed Single Inbuilt Admin Account and Default Approved Companies on Startup
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var hasher = new PasswordHasher<User>();

    // Seed Admin
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
        adminUser.PasswordHash = hasher.HashPassword(adminUser, "Admin@2025");
        dbContext.Users.Add(adminUser);
        dbContext.SaveChanges();
    }

    // Seed Approved Company Accounts for HR Portal
    var defaultCompanies = new[]
    {
        new {
            Email = "virtusa@company.com",
            Password = "Virtusa123@",
            CompanyName = "Virtusa Corporation",
            Industry = "Information Technology & Digital Engineering",
            ContactPerson = "Virtusa Campus Recruitment",
            Phone = "+1 (555) 482-1920"
        },
        new {
            Email = "pasi@company.com",
            Password = "Pasiya123@",
            CompanyName = "Pasi Tech Global",
            Industry = "Software Engineering & Enterprise Cloud",
            ContactPerson = "Pasindu Weerasingha",
            Phone = "+1 (555) 891-2345"
        },
        new {
            Email = "c.vance@acmeglobal.tech",
            Password = "Vanguard#2024Secure!",
            CompanyName = "Acme Global Technologies Inc.",
            Industry = "Software, Cloud & Artificial Intelligence",
            ContactPerson = "Clara Vance",
            Phone = "+1 (555) 234-5678"
        }
    };

    foreach (var c in defaultCompanies)
    {
        var existingUser = dbContext.Users.Include(u => u.CompanyProfile).FirstOrDefault(u => u.Email.ToLower() == c.Email.ToLower());
        if (existingUser != null)
        {
            // Ensure status is Approved so it cannot be trapped in a Pending loop
            if (existingUser.Status != AccountStatus.Approved)
            {
                existingUser.Status = AccountStatus.Approved;
                dbContext.SaveChanges();
            }

            if (existingUser.CompanyProfile == null)
            {
                var companyProfile = new CompanyProfile
                {
                    UserId = existingUser.Id,
                    CompanyName = c.CompanyName,
                    Industry = c.Industry,
                    ContactPersonName = c.ContactPerson,
                    ContactPersonEmail = c.Email.ToLower(),
                    Phone = c.Phone,
                    BusinessRegistrationDocumentUrl = $"{c.CompanyName.Replace(" ", "_")}_BR.pdf"
                };
                dbContext.CompanyProfiles.Add(companyProfile);
                dbContext.SaveChanges();
            }
        }
        else
        {
            var companyUser = new User
            {
                Id = Guid.NewGuid(),
                Email = c.Email.ToLower(),
                Role = UserRole.Company,
                Status = AccountStatus.Approved,
                CreatedAt = DateTime.UtcNow
            };
            companyUser.PasswordHash = hasher.HashPassword(companyUser, c.Password);

            var companyProfile = new CompanyProfile
            {
                UserId = companyUser.Id,
                CompanyName = c.CompanyName,
                Industry = c.Industry,
                ContactPersonName = c.ContactPerson,
                ContactPersonEmail = c.Email.ToLower(),
                Phone = c.Phone,
                BusinessRegistrationDocumentUrl = $"{c.CompanyName.Replace(" ", "_")}_BR.pdf"
            };

            dbContext.Users.Add(companyUser);
            dbContext.CompanyProfiles.Add(companyProfile);
            dbContext.SaveChanges();
        }

        // Ensure sample placement job drives exist for this company
        var targetCompany = dbContext.CompanyProfiles.FirstOrDefault(cp => cp.ContactPersonEmail.ToLower() == c.Email.ToLower());
        if (targetCompany != null && !dbContext.Jobs.Any(j => j.CompanyId == targetCompany.UserId))
        {
            dbContext.Jobs.AddRange(
                new Job
                {
                    JobId = Guid.NewGuid(),
                    CompanyId = targetCompany.UserId,
                    JobTitle = "Backend Engineering Co-op",
                    TargetDomain = "Distributed Systems & Cloud APIs",
                    JobDescriptionSummary = "Join our platform core team building high-throughput microservices and real-time event pipelines.",
                    InternshipType = new[] { "Full-time", "Hybrid" },
                    LocationCity = "San Jose, CA / Remote",
                    MinimumGPA = 3.5m,
                    AllowedYearsOfStudy = new[] { 3, 4 },
                    MandatorySkills = new[] { "Python", "Go", "PostgreSQL", "Docker" },
                    NiceToHaveSkills = new[] { "Kubernetes", "gRPC", "Redis" },
                    PreferredDegreePrograms = new[] { "B.S. Computer Science", "B.S. Software Engineering" },
                    StipendOffered = true,
                    StipendAmountOrDetails = "$45 / hr + Housing Stipend",
                    DurationMonths = 6,
                    ApplicationDeadline = DateTime.UtcNow.AddDays(45),
                    CreatedAt = DateTime.UtcNow.AddDays(-5)
                },
                new Job
                {
                    JobId = Guid.NewGuid(),
                    CompanyId = targetCompany.UserId,
                    JobTitle = "Associate Machine Learning Engineer",
                    TargetDomain = "AI Infrastructure & Agent Systems",
                    JobDescriptionSummary = "Build and optimize autonomous model evaluation pipelines, vector search indexing, and neural models.",
                    InternshipType = new[] { "Full-time" },
                    LocationCity = "Austin, TX / Hybrid",
                    MinimumGPA = 3.6m,
                    AllowedYearsOfStudy = new[] { 4 },
                    MandatorySkills = new[] { "PyTorch", "Python", "CUDA", "FastAPI" },
                    NiceToHaveSkills = new[] { "LangChain", "Vector DBs", "Triton" },
                    PreferredDegreePrograms = new[] { "M.S. Machine Learning", "B.S. Computer Science" },
                    StipendOffered = true,
                    StipendAmountOrDetails = "$55 / hr + Relocation",
                    DurationMonths = 6,
                    ApplicationDeadline = DateTime.UtcNow.AddDays(30),
                    CreatedAt = DateTime.UtcNow.AddDays(-4)
                },
                new Job
                {
                    JobId = Guid.NewGuid(),
                    CompanyId = targetCompany.UserId,
                    JobTitle = "Hardware Systems Intern",
                    TargetDomain = "Embedded Firmware & Robotics",
                    JobDescriptionSummary = "Develop low-level embedded software, real-time operating systems, and interface drivers.",
                    InternshipType = new[] { "Full-time", "On-site" },
                    LocationCity = "Boston, MA",
                    MinimumGPA = 3.4m,
                    AllowedYearsOfStudy = new[] { 3, 4 },
                    MandatorySkills = new[] { "C++", "Verilog", "RTOS", "Linux" },
                    NiceToHaveSkills = new[] { "Altium", "ARM Cortex", "UART/SPI" },
                    PreferredDegreePrograms = new[] { "B.S. Electrical & Computer Eng", "B.S. Robotics" },
                    StipendOffered = true,
                    StipendAmountOrDetails = "$40 / hr",
                    DurationMonths = 4,
                    ApplicationDeadline = DateTime.UtcNow.AddDays(60),
                    CreatedAt = DateTime.UtcNow.AddDays(-3)
                }
            );
            dbContext.SaveChanges();
        }

        // 5b. Seed Controlled Computing Target Domains & Realistic Internship Titles (Idempotent)
        await JobReferenceSeeder.SeedAsync(dbContext);
    }
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

app.UseAuthorization();

app.MapControllers();

app.Run();
