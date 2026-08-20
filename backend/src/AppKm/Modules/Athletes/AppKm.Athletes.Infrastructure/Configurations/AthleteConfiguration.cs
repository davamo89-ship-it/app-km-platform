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

        builder.Property(athlete => athlete.ProfileImageUrl)
            .HasColumnName("profile_image_url")
            .HasMaxLength(500);

        builder.Property(athlete => athlete.CountryCode)
            .HasColumnName("country_code")
            .HasMaxLength(2);

        builder.Property(athlete => athlete.BirthDate)
            .HasColumnName("birth_date");

        builder.Property(athlete => athlete.PreferredSport)
            .HasColumnName("preferred_sport")
            .HasMaxLength(50);
    }
}