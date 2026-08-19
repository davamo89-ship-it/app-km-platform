using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAthleteActivities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "athlete_activities",
                schema: "athletes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    athlete_id = table.Column<Guid>(type: "uuid", nullable: false),
                    strava_activity_id = table.Column<long>(type: "bigint", nullable: false),
                    activity_type = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    distance_kilometers = table.Column<double>(type: "double precision", nullable: false),
                    start_date_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    start_date_local = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    elapsed_time_seconds = table.Column<int>(type: "integer", nullable: false),
                    moving_time_seconds = table.Column<int>(type: "integer", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_athlete_activities", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "UX_athlete_activities_athlete_id_strava_activity_id",
                schema: "athletes",
                table: "athlete_activities",
                columns: new[] { "athlete_id", "strava_activity_id" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "athlete_activities",
                schema: "athletes");
        }
    }
}
