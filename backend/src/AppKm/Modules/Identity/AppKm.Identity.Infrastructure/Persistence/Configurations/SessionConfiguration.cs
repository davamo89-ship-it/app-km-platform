using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Identity.Infrastructure.Persistence.Configurations;

internal sealed class SessionConfiguration
    : IEntityTypeConfiguration<Session>
{
    public void Configure(
        EntityTypeBuilder<Session> builder)
    {
        builder.ToTable(
            "sessions",
            "identity");

        builder.HasKey(session => session.Id);

        builder.Property(session => session.Id)
            .HasConversion(
                sessionId => sessionId.Value,
                value => SessionId.From(value))
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(session => session.UserId)
            .HasConversion(
                userId => userId.Value,
                value => UserId.From(value))
            .HasColumnName("user_id")
            .IsRequired();

        builder.Property(session => session.RefreshTokenHash)
            .HasColumnName("refresh_token_hash")
            .HasMaxLength(128)
            .IsRequired();

        builder.Property(session => session.CreatedAtUtc)
            .HasColumnName("created_at_utc")
            .IsRequired();

        builder.Property(session => session.ExpiresAtUtc)
            .HasColumnName("expires_at_utc")
            .IsRequired();

        builder.Property(session => session.RevokedAtUtc)
            .HasColumnName("revoked_at_utc");

        builder.Ignore(session => session.DomainEvents);

        builder.Ignore(session => session.IsRevoked);

        builder.HasIndex(session => session.RefreshTokenHash)
            .IsUnique();

        builder.HasIndex(session => session.UserId);
    }
}