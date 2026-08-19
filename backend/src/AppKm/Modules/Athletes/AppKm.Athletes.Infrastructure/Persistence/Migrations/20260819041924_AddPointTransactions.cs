using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPointTransactions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "point_transactions",
                schema: "athletes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    athlete_id = table.Column<Guid>(type: "uuid", nullable: false),
                    athlete_activity_id = table.Column<Guid>(type: "uuid", nullable: true),
                    type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    points = table.Column<int>(type: "integer", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    expires_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_point_transactions", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "UX_point_transactions_athlete_activity_type",
                schema: "athletes",
                table: "point_transactions",
                columns: new[] { "athlete_id", "athlete_activity_id", "type" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "point_transactions",
                schema: "athletes");
        }
    }
}
