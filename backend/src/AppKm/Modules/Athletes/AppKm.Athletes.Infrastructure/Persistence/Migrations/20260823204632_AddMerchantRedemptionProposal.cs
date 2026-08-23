using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppKm.Athletes.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMerchantRedemptionProposal : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "athlete_confirmed_at_utc",
                schema: "athletes",
                table: "redemption_requests",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "merchant_id",
                schema: "athletes",
                table: "redemption_requests",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "merchant_proposed_at_utc",
                schema: "athletes",
                table: "redemption_requests",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "proposed_points",
                schema: "athletes",
                table: "redemption_requests",
                type: "integer",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "athlete_confirmed_at_utc",
                schema: "athletes",
                table: "redemption_requests");

            migrationBuilder.DropColumn(
                name: "merchant_id",
                schema: "athletes",
                table: "redemption_requests");

            migrationBuilder.DropColumn(
                name: "merchant_proposed_at_utc",
                schema: "athletes",
                table: "redemption_requests");

            migrationBuilder.DropColumn(
                name: "proposed_points",
                schema: "athletes",
                table: "redemption_requests");
        }
    }
}
