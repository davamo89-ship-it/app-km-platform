using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class CreateAthleteModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "athletes");

            migrationBuilder.CreateTable(
                name: "athletes",
                schema: "athletes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    display_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_athletes", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_athletes_user_id",
                schema: "athletes",
                table: "athletes",
                column: "user_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "athletes",
                schema: "athletes");
        }
    }
}
