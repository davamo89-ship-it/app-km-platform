using AppKm.Athletes.Domain.Aggregates.Athletes;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Athletes.Infrastructure.Persistence.Configurations;

internal sealed class AthleteConfiguration
    : IEntityTypeConfiguration<Athlete>
{
    public void Configure(
        EntityTypeBuilder<Athlete> builder)
    {
        builder.ToTable(
            "athletes",
            "athletes");

        builder.HasKey(athlete => athlete.Id);

        builder.Property(athlete => athlete.Id)
            .HasConversion(
                athleteId => athleteId.Value,
                value => AthleteId.From(value))
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(athlete => athlete.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        builder.Property(athlete => athlete.DisplayName)
            .HasColumnName("display_name")
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(athlete => athlete.Status)
            .HasConversion<string>()
            .HasColumnName("status")
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(athlete => athlete.CreatedAtUtc)
            .HasColumnName("created_at_utc")
            .IsRequired();

        builder.Property(athlete => athlete.UpdatedAtUtc)
            .HasColumnName("updated_at_utc");

        builder.HasIndex(athlete => athlete.UserId)
            .IsUnique();

        builder.Ignore(athlete => athlete.DomainEvents);
    }
}