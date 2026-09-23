using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend_dotnet.Migrations
{
    /// <inheritdoc />
    public partial class AddCreatedAtToJob : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Jobs",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP");

            // Stagger existing seeded jobs so newest jobs appear on top
            migrationBuilder.Sql(@"
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '5 days') WHERE ""JobTitle"" LIKE '%Mobile Solutions%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '4 days') WHERE ""JobTitle"" LIKE '%Associate Machine Learning%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '4 days' + INTERVAL '2 hours') WHERE ""JobTitle"" LIKE '%Full-Stack Enterprise%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '3 days') WHERE ""JobTitle"" LIKE '%Backend Engineering Co-op%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '2 hours') WHERE ""JobTitle"" LIKE '%Cybersecurity%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '2 days') WHERE ""JobTitle"" LIKE '%Cloud DevOps%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '2 hours') WHERE ""JobTitle"" LIKE '%Data Platform%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '1 day') WHERE ""JobTitle"" LIKE '%Hardware Systems%';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '2 hours') WHERE ""JobTitle"" = 'Full Stack Developer Intern';
                UPDATE ""Jobs"" SET ""CreatedAt"" = (CURRENT_TIMESTAMP - INTERVAL '1 hour') WHERE ""JobTitle"" = 'Backend Developer Intern';
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Jobs");
        }
    }
}
