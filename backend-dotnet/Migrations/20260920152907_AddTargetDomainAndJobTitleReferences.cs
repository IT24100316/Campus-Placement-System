using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace backend_dotnet.Migrations
{
    /// <inheritdoc />
    public partial class AddTargetDomainAndJobTitleReferences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "JobTitleId",
                table: "Jobs",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TargetDomainId",
                table: "Jobs",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TargetDomains",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TargetDomains", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "JobTitles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    TargetDomainId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobTitles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobTitles_TargetDomains_TargetDomainId",
                        column: x => x.TargetDomainId,
                        principalTable: "TargetDomains",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Jobs_JobTitleId",
                table: "Jobs",
                column: "JobTitleId");

            migrationBuilder.CreateIndex(
                name: "IX_Jobs_TargetDomainId",
                table: "Jobs",
                column: "TargetDomainId");

            migrationBuilder.CreateIndex(
                name: "IX_JobTitles_TargetDomainId",
                table: "JobTitles",
                column: "TargetDomainId");

            migrationBuilder.CreateIndex(
                name: "IX_JobTitles_Title_TargetDomainId",
                table: "JobTitles",
                columns: new[] { "Title", "TargetDomainId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TargetDomains_Name",
                table: "TargetDomains",
                column: "Name",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_JobTitles_JobTitleId",
                table: "Jobs",
                column: "JobTitleId",
                principalTable: "JobTitles",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_TargetDomains_TargetDomainId",
                table: "Jobs",
                column: "TargetDomainId",
                principalTable: "TargetDomains",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_JobTitles_JobTitleId",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_TargetDomains_TargetDomainId",
                table: "Jobs");

            migrationBuilder.DropTable(
                name: "JobTitles");

            migrationBuilder.DropTable(
                name: "TargetDomains");

            migrationBuilder.DropIndex(
                name: "IX_Jobs_JobTitleId",
                table: "Jobs");

            migrationBuilder.DropIndex(
                name: "IX_Jobs_TargetDomainId",
                table: "Jobs");

            migrationBuilder.DropColumn(
                name: "JobTitleId",
                table: "Jobs");

            migrationBuilder.DropColumn(
                name: "TargetDomainId",
                table: "Jobs");
        }
    }
}
