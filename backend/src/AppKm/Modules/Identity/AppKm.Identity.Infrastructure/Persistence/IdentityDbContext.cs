using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.PushDevices;
using AppKm.Identity.Domain.Aggregates.Roles;
using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Identity.Infrastructure.Persistence;

public sealed class IdentityDbContext : DbContext, IUnitOfWork
{
    public IdentityDbContext(
        DbContextOptions<IdentityDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();

    public DbSet<Session> Sessions => Set<Session>();

    public DbSet<Role> Roles => Set<Role>();

    public DbSet<UserRole> UserRoles => Set<UserRole>();

    public DbSet<PushDevice> PushDevices => Set<PushDevice>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(IdentityDbContext).Assembly);

        base.OnModelCreating(modelBuilder);
    }
}
