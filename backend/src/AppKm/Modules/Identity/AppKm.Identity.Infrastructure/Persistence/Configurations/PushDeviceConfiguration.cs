using AppKm.Identity.Domain.Aggregates.PushDevices;
using AppKm.Identity.Domain.Aggregates.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Identity.Infrastructure.Persistence.Configurations;

internal sealed class PushDeviceConfiguration
    : IEntityTypeConfiguration<PushDevice>
{
    public void Configure(
        EntityTypeBuilder<PushDevice> builder)
    {
        builder.ToTable(
            "push_devices",
            "identity");

        builder.HasKey(pushDevice => pushDevice.Id);

        builder.Property(pushDevice => pushDevice.Id)
            .HasConversion(
                pushDeviceId => pushDeviceId.Value,
                value => PushDeviceId.From(value))
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(pushDevice => pushDevice.UserId)
            .HasConversion(
                userId => userId.Value,
                value => UserId.From(value))
            .HasColumnName("user_id")
            .IsRequired();

        builder.Property(pushDevice => pushDevice.Token)
            .HasColumnName("token")
            .HasMaxLength(4096)
            .IsRequired();

        builder.Property(pushDevice => pushDevice.Platform)
            .HasColumnName("platform")
            .HasMaxLength(30)
            .IsRequired();

        builder.Property(pushDevice => pushDevice.IsActive)
            .HasColumnName("is_active")
            .IsRequired();

        builder.Property(pushDevice => pushDevice.CreatedAtUtc)
            .HasColumnName("created_at_utc")
            .IsRequired();

        builder.Property(pushDevice => pushDevice.UpdatedAtUtc)
            .HasColumnName("updated_at_utc")
            .IsRequired();

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(pushDevice => pushDevice.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(pushDevice => pushDevice.Token)
            .IsUnique();

        builder.HasIndex(pushDevice => new
        {
            pushDevice.UserId,
            pushDevice.IsActive
        });

        builder.Ignore(pushDevice => pushDevice.DomainEvents);
    }
}
