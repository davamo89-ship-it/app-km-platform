using AppKm.Athletes.Domain.Aggregates.PointTransactions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Athletes.Infrastructure.Persistence.Configurations;

internal sealed class PointTransactionConfiguration
    : IEntityTypeConfiguration<PointTransaction>
{
    public void Configure(
        EntityTypeBuilder<PointTransaction> builder)
    {
        builder.ToTable(
            "point_transactions",
            "athletes");

        builder.HasKey(transaction =>
            transaction.Id);

        builder.Property(transaction =>
                transaction.Id)
            .HasConversion(
                id => id.Value,
                value => new PointTransactionId(value))
            .HasColumnName("id");

        builder.Property(transaction =>
                transaction.AthleteId)
            .HasColumnName("athlete_id")
            .IsRequired();

        builder.Property(transaction =>
                transaction.AthleteActivityId)
            .HasColumnName("athlete_activity_id");

        builder.Property(transaction =>
                transaction.Type)
            .HasConversion<string>()
            .HasColumnName("type")
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(transaction =>
                transaction.Points)
            .HasColumnName("points")
            .IsRequired();

        builder.Property(transaction =>
                transaction.CreatedAtUtc)
            .HasColumnName("created_at_utc")
            .IsRequired();

        builder.Property(transaction =>
                transaction.ExpiresAtUtc)
            .HasColumnName("expires_at_utc");

        builder.HasIndex(transaction => new
            {
                transaction.AthleteId,
                transaction.AthleteActivityId,
                transaction.Type
            })
            .IsUnique()
            .HasDatabaseName(
                "UX_point_transactions_athlete_activity_type");
    }
}