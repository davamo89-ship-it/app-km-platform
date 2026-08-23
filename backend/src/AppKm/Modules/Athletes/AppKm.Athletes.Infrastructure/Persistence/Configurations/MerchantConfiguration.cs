using AppKm.Athletes.Domain.Aggregates.Merchants;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Athletes.Infrastructure.Persistence.Configurations;

internal sealed class MerchantConfiguration
    : IEntityTypeConfiguration<Merchant>
{
    public void Configure(
        EntityTypeBuilder<Merchant> builder)
    {
        builder.ToTable(
            "merchants",
            "athletes");

        builder.HasKey(merchant =>
            merchant.Id);

        builder.Property(merchant =>
                merchant.Id)
            .HasConversion(
                id => id.Value,
                value => new MerchantId(value))
            .HasColumnName("id");

        builder.Property(merchant =>
                merchant.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        builder.Property(merchant =>
                merchant.BusinessName)
            .HasColumnName("business_name")
            .HasMaxLength(150)
            .IsRequired();

        builder.Property(merchant =>
                merchant.Status)
            .HasConversion<string>()
            .HasColumnName("status")
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(merchant =>
                merchant.CreatedAtUtc)
            .HasColumnName("created_at_utc")
            .IsRequired();

        builder.Property(merchant =>
                merchant.UpdatedAtUtc)
            .HasColumnName("updated_at_utc");

        builder.HasIndex(merchant =>
                merchant.UserId)
            .IsUnique()
            .HasDatabaseName(
                "UX_merchants_user_id");
    }
}