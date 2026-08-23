using AppKm.Athletes.Domain.Aggregates.Athletes;
using Microsoft.EntityFrameworkCore;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;
using AppKm.Athletes.Domain.Aggregates.PointTransactions;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using AppKm.Athletes.Domain.Aggregates.Merchants;

namespace AppKm.Athletes.Infrastructure.Persistence;

public sealed class AthleteDbContext : DbContext
{
    public AthleteDbContext(
        DbContextOptions<AthleteDbContext> options)
        : base(options)
    {
    }

    public DbSet<Athlete> Athletes => Set<Athlete>();
    public DbSet<StravaConnection> StravaConnections =>
    Set<StravaConnection>();
    public DbSet<AthleteActivity> AthleteActivities =>
    Set<AthleteActivity>();
    public DbSet<PointTransaction> PointTransactions =>
    Set<PointTransaction>();
    public DbSet<RedemptionRequest> RedemptionRequests =>
    Set<RedemptionRequest>();
    public DbSet<Merchant> Merchants =>
    Set<Merchant>();

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(AthleteDbContext).Assembly);

        base.OnModelCreating(modelBuilder);
    }
}