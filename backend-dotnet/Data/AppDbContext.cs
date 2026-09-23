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
    public DbSet<CompanyProfile> CompanyProfiles => Set<CompanyProfile>();
    public DbSet<CompanyStaffProfile> CompanyStaffProfiles => Set<CompanyStaffProfile>();
    public DbSet<Job> Jobs => Set<Job>();
    public DbSet<Application> Applications => Set<Application>();
    public DbSet<TargetDomain> TargetDomains => Set<TargetDomain>();
    public DbSet<JobTitleReference> JobTitles => Set<JobTitleReference>();
    public DbSet<SkillEquivalence> SkillEquivalences => Set<SkillEquivalence>();

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

            entity.Property(u => u.Status)
                .HasConversion<string>()
                .IsRequired();

            entity.Property(u => u.CreatedAt)
                .IsRequired();
        });

        // -------------------------------------------------------------
        // 2. StudentProfile Entity Configuration (1:1 with User)
        // -------------------------------------------------------------
        modelBuilder.Entity<StudentProfile>(entity =>
        {
            entity.HasKey(sp => sp.UserId);

            entity.Property(sp => sp.FullName)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(sp => sp.Phone)
                .IsRequired()
                .HasMaxLength(50);

            entity.Property(sp => sp.GPA)
                .HasPrecision(3, 2);

            entity.Property(sp => sp.Skills)
                .HasColumnType("text[]");

            entity.Property(sp => sp.ToolsAndTechnologies)
                .HasColumnType("text[]");

            entity.Property(sp => sp.InternshipType)
                .HasColumnType("text[]");

            entity.Property(sp => sp.PreferredLocations)
                .HasColumnType("text[]");

            entity.HasOne(sp => sp.User)
                .WithOne(u => u.StudentProfile)
                .HasForeignKey<StudentProfile>(sp => sp.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // -------------------------------------------------------------
        // 3. CompanyProfile Entity Configuration (1:1 with User)
        // -------------------------------------------------------------
        modelBuilder.Entity<CompanyProfile>(entity =>
        {
            entity.HasKey(cp => cp.UserId);

            entity.Property(cp => cp.CompanyName)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(cp => cp.Industry)
                .IsRequired()
                .HasMaxLength(150);

            entity.Property(cp => cp.ContactPersonName)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(cp => cp.ContactPersonEmail)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(cp => cp.Phone)
                .IsRequired()
                .HasMaxLength(50);

            entity.HasOne(cp => cp.User)
                .WithOne(u => u.CompanyProfile)
                .HasForeignKey<CompanyProfile>(cp => cp.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // -------------------------------------------------------------
        // 3b. CompanyStaffProfile Entity Configuration
        // -------------------------------------------------------------
        modelBuilder.Entity<CompanyStaffProfile>(entity =>
        {
            entity.HasKey(sp => sp.UserId);

            entity.Property(sp => sp.FullName)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(sp => sp.StaffId)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(sp => sp.JobPosition)
                .IsRequired()
                .HasMaxLength(150);

            // 1:1 with User
            entity.HasOne(sp => sp.User)
                .WithOne(u => u.CompanyStaffProfile)
                .HasForeignKey<CompanyStaffProfile>(sp => sp.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // N:1 with CompanyProfile
            entity.HasOne(sp => sp.Company)
                .WithMany(cp => cp.StaffMembers)
                .HasForeignKey(sp => sp.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // -------------------------------------------------------------
        // 4. Job Entity Configuration (1:N with CompanyProfile)
        // -------------------------------------------------------------
        modelBuilder.Entity<Job>(entity =>
        {
            entity.HasKey(j => j.JobId);

            entity.Property(j => j.JobTitle)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(j => j.TargetDomain)
                .IsRequired()
                .HasMaxLength(150);

            entity.Property(j => j.MinimumGPA)
                .HasPrecision(3, 2);

            entity.Property(j => j.InternshipType)
                .HasColumnType("text[]");

            entity.Property(j => j.AllowedYearsOfStudy)
                .HasColumnType("integer[]");

            entity.Property(j => j.MandatorySkills)
                .HasColumnType("text[]");

            entity.Property(j => j.NiceToHaveSkills)
                .HasColumnType("text[]");

            entity.Property(j => j.PreferredDegreePrograms)
                .HasColumnType("text[]");

            entity.Property(j => j.CreatedAt)
                .IsRequired()
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasOne(j => j.Company)
                .WithMany(cp => cp.Jobs)
                .HasForeignKey(j => j.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(j => j.DomainReference)
                .WithMany(td => td.Jobs)
                .HasForeignKey(j => j.TargetDomainId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(j => j.JobTitleReference)
                .WithMany(jt => jt.Jobs)
                .HasForeignKey(j => j.JobTitleId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // -------------------------------------------------------------
        // 4b. TargetDomain & JobTitleReference Configurations
        // -------------------------------------------------------------
        modelBuilder.Entity<TargetDomain>(entity =>
        {
            entity.HasKey(td => td.Id);

            entity.Property(td => td.Name)
                .IsRequired()
                .HasMaxLength(150);

            entity.HasIndex(td => td.Name)
                .IsUnique();
        });

        modelBuilder.Entity<JobTitleReference>(entity =>
        {
            entity.HasKey(jt => jt.Id);

            entity.Property(jt => jt.Title)
                .IsRequired()
                .HasMaxLength(200);

            entity.HasOne(jt => jt.TargetDomain)
                .WithMany(td => td.JobTitles)
                .HasForeignKey(jt => jt.TargetDomainId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(jt => new { jt.Title, jt.TargetDomainId })
                .IsUnique();
        });

        // -------------------------------------------------------------
        // 5. Application Entity Configuration (Student + Job Foreign Keys)
        // -------------------------------------------------------------
        modelBuilder.Entity<Application>(entity =>
        {
            entity.HasKey(a => a.AppId);

            entity.Property(a => a.SummaryReport)
                .HasColumnType("jsonb")
                .IsRequired();

            entity.Property(a => a.Status)
                .HasConversion<string>()
                .IsRequired();

            // FK to Student (User)
            entity.HasOne(a => a.Student)
                .WithMany(u => u.Applications)
                .HasForeignKey(a => a.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // FK to Job
            entity.HasOne(a => a.Job)
                .WithMany(j => j.Applications)
                .HasForeignKey(a => a.JobId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // -------------------------------------------------------------
        // 6. SkillEquivalence Entity Configuration
        // -------------------------------------------------------------
        modelBuilder.Entity<SkillEquivalence>(entity =>
        {
            entity.HasKey(e => e.Id);
            
            entity.Property(e => e.TermA).IsRequired();
            entity.Property(e => e.TermB).IsRequired();
            
            entity.HasIndex(e => new { e.TermA, e.TermB }).IsUnique();
            
            entity.Property(e => e.Source).HasDefaultValue("llm");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
        });
    }
}
