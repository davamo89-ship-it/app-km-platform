using AppKm.Athletes.Domain.Aggregates.AthleteActivities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AppKm.Athletes.Infrastructure.Persistence.Configurations;

internal sealed class AthleteActivityConfiguration
    : IEntityTypeConfiguration<AthleteActivity>
{
    public void Configure(
        EntityTypeBuilder<AthleteActivity> builder)
    {
        builder.ToTable(
            "athlete_activities",
            "athletes");

        builder.HasKey(activity =>
            activity.Id);

        builder.Property(activity =>
                activity.Id)
            .HasConversion(
                id => id.Value,
                value => new AthleteActivityId(value))
            .HasColumnName("id");

        builder.Property(activity =>
                activity.AthleteId)
            .HasConversion(
                id => id.Value,
                value => new(value))
            .HasColumnName("athlete_id")
            .IsRequired();

        builder.Property(activity =>
                activity.StravaActivityId)
            .HasColumnName("strava_activity_id")
            .IsRequired();

        builder.Property(activity =>
                activity.ActivityType)
            .HasConversion<string>()
            .HasColumnName("activity_type")
            .HasMaxLength(30)
            .IsRequired();

        builder.Property(activity =>
                activity.DistanceKilometers)
            .HasColumnName("distance_kilometers")
            .IsRequired();

        builder.Property(activity =>
                 activity.Points)
            .HasColumnName("points")
            .IsRequired();    

        builder.Property(activity =>
                activity.StartDateUtc)
            .HasColumnName("start_date_utc")
            .IsRequired();

        builder.Property(activity =>
                activity.StartDateLocal)
            .HasColumnName("start_date_local")
            .IsRequired();

        builder.Property(activity =>
                activity.ElapsedTimeSeconds)
            .HasColumnName("elapsed_time_seconds")
            .IsRequired();

        builder.Property(activity =>
                activity.MovingTimeSeconds)
            .HasColumnName("moving_time_seconds")
            .IsRequired();

        builder.Property(activity =>
                activity.CreatedAtUtc)
            .HasColumnName("created_at_utc")
            .IsRequired();

        builder.HasIndex(activity => new
            {
                activity.AthleteId,
                activity.StravaActivityId
            })
            .IsUnique()
            .HasDatabaseName(
                "UX_athlete_activities_athlete_id_strava_activity_id");
    }
}