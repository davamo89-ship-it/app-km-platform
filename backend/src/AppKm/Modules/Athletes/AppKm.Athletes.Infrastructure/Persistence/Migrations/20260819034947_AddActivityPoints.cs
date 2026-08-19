using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddActivityPoints : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "points",
                schema: "athletes",
                table: "athlete_activities",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "points",
                schema: "athletes",
                table: "athlete_activities");
        }
    }
}
