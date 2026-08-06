using AppKm.Identity.Domain.Aggregates.Roles;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Identity.Infrastructure.Persistence.Configurations;

internal sealed class RoleConfiguration
    : IEntityTypeConfiguration<Role>
{
    public void Configure(
        EntityTypeBuilder<Role> builder)
    {
        builder.ToTable(
            "roles",
            "identity");

        builder.HasKey(role => role.Id);

        builder.Property(role => role.Id)
            .HasConversion(
                roleId => roleId.Value,
                value => RoleId.From(value))
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(role => role.Name)
            .HasColumnName("name")
            .HasMaxLength(50)
            .IsRequired();

        builder.HasIndex(role => role.Name)
            .IsUnique();

        builder.Ignore(role => role.DomainEvents);

        builder.HasData(
            new
            {
                Id = RoleIds.Athlete,
                Name = RoleNames.Athlete
            },
            new
            {
                Id = RoleIds.Merchant,
                Name = RoleNames.Merchant
            },
            new
            {
                Id = RoleIds.Admin,
                Name = RoleNames.Admin
            });
    }
}