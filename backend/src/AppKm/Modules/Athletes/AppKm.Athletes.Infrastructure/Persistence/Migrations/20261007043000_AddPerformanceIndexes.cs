using AppKm.Athletes.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations;

[DbContext(typeof(AthleteDbContext))]
[Migration("20261007043000_AddPerformanceIndexes")]
public partial class AddPerformanceIndexes
    : Migration
{
    protected override void Up(
        MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateIndex(
            name: "IX_athlete_activities_athlete_id_start_date_utc",
            schema: "athletes",
            table: "athlete_activities",
            columns: new[]
            {
                "athlete_id",
                "start_date_utc"
            });

        migrationBuilder.CreateIndex(
            name: "IX_point_transactions_athlete_id_type",
            schema: "athletes",
            table: "point_transactions",
            columns: new[]
            {
                "athlete_id",
                "type"
            });

        migrationBuilder.CreateIndex(
            name: "IX_point_transactions_athlete_id_created_at_utc",
            schema: "athletes",
            table: "point_transactions",
            columns: new[]
            {
                "athlete_id",
                "created_at_utc"
            });

        migrationBuilder.CreateIndex(
            name: "IX_redemption_requests_athlete_id_created_at_utc",
            schema: "athletes",
            table: "redemption_requests",
            columns: new[]
            {
                "athlete_id",
                "created_at_utc"
            });

        migrationBuilder.CreateIndex(
            name: "IX_redemption_requests_athlete_id_status_expires_at_utc",
            schema: "athletes",
            table: "redemption_requests",
            columns: new[]
            {
                "athlete_id",
                "status",
                "expires_at_utc"
            });

        migrationBuilder.CreateIndex(
            name: "IX_redemption_requests_merchant_id_proposed_created_at_utc",
            schema: "athletes",
            table: "redemption_requests",
            columns: new[]
            {
                "merchant_id",
                "merchant_proposed_at_utc",
                "created_at_utc"
            });
    }

    protected override void Down(
        MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(
            name: "IX_athlete_activities_athlete_id_start_date_utc",
            schema: "athletes",
            table: "athlete_activities");

        migrationBuilder.DropIndex(
            name: "IX_point_transactions_athlete_id_type",
            schema: "athletes",
            table: "point_transactions");

        migrationBuilder.DropIndex(
            name: "IX_point_transactions_athlete_id_created_at_utc",
            schema: "athletes",
            table: "point_transactions");

        migrationBuilder.DropIndex(
            name: "IX_redemption_requests_athlete_id_created_at_utc",
            schema: "athletes",
            table: "redemption_requests");

        migrationBuilder.DropIndex(
            name: "IX_redemption_requests_athlete_id_status_expires_at_utc",
            schema: "athletes",
            table: "redemption_requests");

        migrationBuilder.DropIndex(
            name: "IX_redemption_requests_merchant_id_proposed_created_at_utc",
            schema: "athletes",
            table: "redemption_requests");
    }
}
