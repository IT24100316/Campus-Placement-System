using System;
using backend_dotnet.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend_dotnet.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20261004120000_AddCvUploadedAt")]
public partial class AddCvUploadedAt : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<DateTime>(
            name: "CvUploadedAt",
            table: "StudentProfiles",
            type: "timestamp with time zone",
            nullable: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "CvUploadedAt",
            table: "StudentProfiles");
    }
}
