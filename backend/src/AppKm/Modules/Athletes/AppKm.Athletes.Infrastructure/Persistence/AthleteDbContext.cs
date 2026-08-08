using AppKm.Athletes.Domain.Aggregates.Athletes;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Athletes.Infrastructure.Persistence;

public sealed class AthleteDbContext : DbContext
{
    public AthleteDbContext(
        DbContextOptions<AthleteDbContext> options)
        : base(options)
    {
    }

    public DbSet<Athlete> Athletes => Set<Athlete>();

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(AthleteDbContext).Assembly);

        base.OnModelCreating(modelBuilder);
    }
}