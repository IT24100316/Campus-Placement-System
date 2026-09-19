using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend_dotnet.Migrations
{
    /// <inheritdoc />
    public partial class InitialMultiAgentCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: false),
                    Role = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CompanyProfiles",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyName = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Industry = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    ContactPersonEmail = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    BusinessRegistrationDocumentUrl = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CompanyProfiles", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_CompanyProfiles_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StudentProfiles",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    FullName = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Phone = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    CampusIdPhotoUrl = table.Column<string>(type: "text", nullable: false),
                    PortfolioUrl = table.Column<string>(type: "text", nullable: true),
                    UniversityName = table.Column<string>(type: "text", nullable: false),
                    AcademicStatus = table.Column<string>(type: "text", nullable: false),
                    DegreeProgram = table.Column<string>(type: "text", nullable: false),
                    CurrentYearOfStudy = table.Column<int>(type: "integer", nullable: false),
                    GPA = table.Column<decimal>(type: "numeric(3,2)", precision: 3, scale: 2, nullable: false),
                    ExpectedGraduationDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DesiredJobTitle = table.Column<string>(type: "text", nullable: false),
                    PrimaryDomain = table.Column<string>(type: "text", nullable: false),
                    CareerObjectivesSummary = table.Column<string>(type: "text", nullable: false),
                    Skills = table.Column<string[]>(type: "text[]", nullable: false),
                    ToolsAndTechnologies = table.Column<string[]>(type: "text[]", nullable: false),
                    InternshipType = table.Column<string[]>(type: "text[]", nullable: false),
                    LectureScheduleType = table.Column<string>(type: "text", nullable: false),
                    PreferredLocations = table.Column<string[]>(type: "text[]", nullable: false),
                    CvPdfUrl = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StudentProfiles", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_StudentProfiles_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Jobs",
                columns: table => new
                {
                    JobId = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    JobTitle = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    TargetDomain = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    JobDescriptionSummary = table.Column<string>(type: "text", nullable: false),
                    InternshipType = table.Column<string[]>(type: "text[]", nullable: false),
                    LocationCity = table.Column<string>(type: "text", nullable: false),
                    MinimumGPA = table.Column<decimal>(type: "numeric(3,2)", precision: 3, scale: 2, nullable: false),
                    AllowedYearsOfStudy = table.Column<int[]>(type: "integer[]", nullable: false),
                    MandatorySkills = table.Column<string[]>(type: "text[]", nullable: false),
                    NiceToHaveSkills = table.Column<string[]>(type: "text[]", nullable: false),
                    PreferredDegreePrograms = table.Column<string[]>(type: "text[]", nullable: false),
                    StipendOffered = table.Column<bool>(type: "boolean", nullable: false),
                    StipendAmountOrDetails = table.Column<string>(type: "text", nullable: true),
                    DurationMonths = table.Column<int>(type: "integer", nullable: false),
                    ApplicationDeadline = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Jobs", x => x.JobId);
                    table.ForeignKey(
                        name: "FK_Jobs_CompanyProfiles_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "CompanyProfiles",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Applications",
                columns: table => new
                {
                    AppId = table.Column<Guid>(type: "uuid", nullable: false),
                    StudentId = table.Column<Guid>(type: "uuid", nullable: false),
                    JobId = table.Column<Guid>(type: "uuid", nullable: false),
                    MatchScore = table.Column<int>(type: "integer", nullable: false),
                    SummaryReport = table.Column<string>(type: "jsonb", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    InterviewDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    InterviewTime = table.Column<TimeSpan>(type: "interval", nullable: true),
                    CompanyMessage = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Applications", x => x.AppId);
                    table.ForeignKey(
                        name: "FK_Applications_Jobs_JobId",
                        column: x => x.JobId,
                        principalTable: "Jobs",
                        principalColumn: "JobId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Applications_Users_StudentId",
                        column: x => x.StudentId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Applications_JobId",
                table: "Applications",
                column: "JobId");

            migrationBuilder.CreateIndex(
                name: "IX_Applications_StudentId",
                table: "Applications",
                column: "StudentId");

            migrationBuilder.CreateIndex(
                name: "IX_Jobs_CompanyId",
                table: "Jobs",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Applications");

            migrationBuilder.DropTable(
                name: "StudentProfiles");

            migrationBuilder.DropTable(
                name: "Jobs");

            migrationBuilder.DropTable(
                name: "CompanyProfiles");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
