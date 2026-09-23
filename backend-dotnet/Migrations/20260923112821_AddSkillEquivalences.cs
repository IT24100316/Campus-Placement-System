using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend_dotnet.Migrations
{
    /// <inheritdoc />
    public partial class AddSkillEquivalences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SkillEquivalences",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TermA = table.Column<string>(type: "text", nullable: false),
                    TermB = table.Column<string>(type: "text", nullable: false),
                    IsMatch = table.Column<bool>(type: "boolean", nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: true),
                    Source = table.Column<string>(type: "text", nullable: false, defaultValue: "llm"),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SkillEquivalences", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SkillEquivalences_TermA_TermB",
                table: "SkillEquivalences",
                columns: new[] { "TermA", "TermB" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SkillEquivalences");
        }
    }
}
