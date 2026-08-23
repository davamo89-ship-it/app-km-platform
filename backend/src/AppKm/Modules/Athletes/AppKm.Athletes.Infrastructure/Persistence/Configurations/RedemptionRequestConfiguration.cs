using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Athletes.Infrastructure.Persistence.Configurations;

internal sealed class RedemptionRequestConfiguration
    : IEntityTypeConfiguration<RedemptionRequest>
{
    public void Configure(
        EntityTypeBuilder<RedemptionRequest> builder)
    {
        builder.ToTable(
            "redemption_requests",
            "athletes");

        builder.HasKey(request =>
            request.Id);

        builder.Property(request =>
                request.Id)
            .HasConversion(
                id => id.Value,
                value => new RedemptionRequestId(value))
            .HasColumnName("id");

        builder.Property(request =>
                request.AthleteId)
            .HasColumnName("athlete_id")
            .IsRequired();

        builder.Property(request =>
                request.Code)
            .HasColumnName("code")
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(request =>
                request.RequestedPoints)
            .HasColumnName("requested_points")
            .IsRequired();

        builder.Property(request =>
                request.Status)
            .HasConversion<string>()
            .HasColumnName("status")
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(request =>
                request.CreatedAtUtc)
            .HasColumnName("created_at_utc")
            .IsRequired();

        builder.Property(request =>
                request.ExpiresAtUtc)
            .HasColumnName("expires_at_utc")
            .IsRequired();

        builder.Property(request =>
                request.CompletedAtUtc)
            .HasColumnName("completed_at_utc");

        builder.HasIndex(request =>
                request.Code)
            .IsUnique()
            .HasDatabaseName(
                "UX_redemption_requests_code");

        builder.Property(request =>
        request.MerchantId)
              .HasColumnName("merchant_id");

        builder.Property(request =>
                request.ProposedPoints)
            .HasColumnName("proposed_points");

        builder.Property(request =>
                request.MerchantProposedAtUtc)
            .HasColumnName("merchant_proposed_at_utc");

        builder.Property(request =>
                request.AthleteConfirmedAtUtc)
            .HasColumnName("athlete_confirmed_at_utc");
    }
}