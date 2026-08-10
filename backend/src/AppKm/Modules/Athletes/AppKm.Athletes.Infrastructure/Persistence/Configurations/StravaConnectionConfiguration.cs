using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Athletes.Infrastructure.Persistence.Configurations;

internal sealed class StravaConnectionConfiguration
    : IEntityTypeConfiguration<StravaConnection>
{
    public void Configure(
        EntityTypeBuilder<StravaConnection> builder)
    {
        builder.ToTable(
            "strava_connections",
            "athletes");

        builder.HasKey(connection => connection.Id);

        builder.Property(connection => connection.Id)
            .HasConversion(
                id => id.Value,
                value => StravaConnectionId.From(value))
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(connection => connection.AthleteId)
            .HasColumnName("athlete_id")
            .IsRequired();

        builder.Property(connection => connection.StravaAthleteId)
            .HasColumnName("strava_athlete_id")
            .IsRequired();

        builder.Property(connection => connection.AccessTokenEncrypted)
            .HasColumnName("access_token_encrypted")
            .HasColumnType("text")
            .IsRequired();

        builder.Property(connection => connection.RefreshTokenEncrypted)
            .HasColumnName("refresh_token_encrypted")
            .HasColumnType("text")
            .IsRequired();

        builder.Property(connection => connection.AccessTokenExpiresAtUtc)
            .HasColumnName("access_token_expires_at_utc")
            .IsRequired();

        builder.Property(connection => connection.ConnectedAtUtc)
            .HasColumnName("connected_at_utc")
            .IsRequired();

        builder.Property(connection => connection.UpdatedAtUtc)
            .HasColumnName("updated_at_utc");

        builder.Property(connection => connection.Status)
            .HasConversion<string>()
            .HasColumnName("status")
            .HasMaxLength(50)
            .IsRequired();

        builder.HasIndex(connection => connection.AthleteId)
            .IsUnique();

        builder.HasIndex(connection => connection.StravaAthleteId)
            .IsUnique();

        builder.Ignore(connection => connection.DomainEvents);
    }
}