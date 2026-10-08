using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Identity.Infrastructure.Persistence.Migrations
{
    public partial class AddPasswordResetFields : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "password_reset_code_hash",
                schema: "identity",
                table: "users",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "password_reset_expires_at_utc",
                schema: "identity",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "password_reset_requested_at_utc",
                schema: "identity",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "password_reset_code_hash",
                schema: "identity",
                table: "users");

            migrationBuilder.DropColumn(
                name: "password_reset_expires_at_utc",
                schema: "identity",
                table: "users");

            migrationBuilder.DropColumn(
                name: "password_reset_requested_at_utc",
                schema: "identity",
                table: "users");
        }
    }
}
