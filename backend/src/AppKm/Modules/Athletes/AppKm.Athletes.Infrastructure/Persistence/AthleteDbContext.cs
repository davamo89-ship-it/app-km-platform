using AppKm.Athletes.Domain.Aggregates.Athletes;
using Microsoft.EntityFrameworkCore;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;

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

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(AthleteDbContext).Assembly);

        base.OnModelCreating(modelBuilder);
    }
}