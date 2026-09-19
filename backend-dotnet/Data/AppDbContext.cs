using backend_dotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<StudentProfile> StudentProfiles => Set<StudentProfile>();
    public DbSet<Job> Jobs => Set<Job>();
    public DbSet<Application> Applications => Set<Application>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // -------------------------------------------------------------
        // 1. User Entity Configuration
        // -------------------------------------------------------------
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);

            entity.Property(u => u.Email)
                .IsRequired()
                .HasMaxLength(255);

            entity.HasIndex(u => u.Email)
                .IsUnique();

            entity.Property(u => u.PasswordHash)
                .IsRequired();

            entity.Property(u => u.Role)
                .HasConversion<string>()
                .IsRequired();
        });

        // -------------------------------------------------------------
        // 2. StudentProfile Entity Configuration (1:1 with User)
        // -------------------------------------------------------------
        modelBuilder.Entity<StudentProfile>(entity =>
        {
            entity.HasKey(sp => sp.StudentId);

            entity.Property(sp => sp.Skills)
                .HasColumnType("text[]");

            entity.Property(sp => sp.Languages)
                .HasColumnType("text[]");

            entity.Property(sp => sp.GPA)
                .HasPrecision(3, 2);

            entity.HasOne(sp => sp.Student)
                .WithOne(u => u.StudentProfile)
                .HasForeignKey<StudentProfile>(sp => sp.StudentId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // -------------------------------------------------------------
        // 3. Job Entity Configuration (1:N User(Company) -> Jobs)
        // -------------------------------------------------------------
        modelBuilder.Entity<Job>(entity =>
        {
            entity.HasKey(j => j.JobId);

            entity.Property(j => j.Req_Skills)
                .HasColumnType("text[]");

            entity.Property(j => j.Req_Languages)
                .HasColumnType("text[]");

            entity.Property(j => j.Min_GPA)
                .HasPrecision(3, 2);

            entity.HasOne(j => j.Company)
                .WithMany(u => u.PostedJobs)
                .HasForeignKey(j => j.CompanyId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // -------------------------------------------------------------
        // 4. Application Entity Configuration (Student + Job Foreign Keys)
        // -------------------------------------------------------------
        modelBuilder.Entity<Application>(entity =>
        {
            entity.HasKey(a => a.AppId);

            entity.Property(a => a.SummaryReport)
                .HasColumnType("jsonb");

            entity.Property(a => a.Status)
                .IsRequired()
                .HasMaxLength(50);

            // Student FK (User)
            entity.HasOne(a => a.Student)
                .WithMany(u => u.Applications)
                .HasForeignKey(a => a.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Job FK
            entity.HasOne(a => a.Job)
                .WithMany(j => j.Applications)
                .HasForeignKey(a => a.JobId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // -------------------------------------------------------------
        // 5. AuditLog Entity Configuration
        // -------------------------------------------------------------
        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(al => al.LogId);

            entity.Property(al => al.Action)
                .IsRequired()
                .HasMaxLength(255);

            entity.HasOne(al => al.Performer)
                .WithMany()
                .HasForeignKey(al => al.PerformedBy)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
