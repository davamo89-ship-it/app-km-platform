using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddStravaConnections : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "strava_connections",
                schema: "athletes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    athlete_id = table.Column<Guid>(type: "uuid", nullable: false),
                    strava_athlete_id = table.Column<long>(type: "bigint", nullable: false),
                    access_token_encrypted = table.Column<string>(type: "text", nullable: false),
                    refresh_token_encrypted = table.Column<string>(type: "text", nullable: false),
                    access_token_expires_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    connected_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_strava_connections", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_strava_connections_athlete_id",
                schema: "athletes",
                table: "strava_connections",
                column: "athlete_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_strava_connections_strava_athlete_id",
                schema: "athletes",
                table: "strava_connections",
                column: "strava_athlete_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "strava_connections",
                schema: "athletes");
        }
    }
}
