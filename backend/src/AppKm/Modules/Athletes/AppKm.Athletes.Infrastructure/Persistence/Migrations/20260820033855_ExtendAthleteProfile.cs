using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ExtendAthleteProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateOnly>(
                name: "birth_date",
                schema: "athletes",
                table: "athletes",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "country_code",
                schema: "athletes",
                table: "athletes",
                type: "character varying(2)",
                maxLength: 2,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "preferred_sport",
                schema: "athletes",
                table: "athletes",
                type: "character varying(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "profile_image_url",
                schema: "athletes",
                table: "athletes",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "birth_date",
                schema: "athletes",
                table: "athletes");

            migrationBuilder.DropColumn(
                name: "country_code",
                schema: "athletes",
                table: "athletes");

            migrationBuilder.DropColumn(
                name: "preferred_sport",
                schema: "athletes",
                table: "athletes");

            migrationBuilder.DropColumn(
                name: "profile_image_url",
                schema: "athletes",
                table: "athletes");
        }
    }
}
