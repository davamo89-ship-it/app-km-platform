using AppKm.Athletes.Application.Interfaces;

namespace AppKm.Athletes.Infrastructure.Persistence;

internal sealed class AthleteUnitOfWork
    : IAthleteUnitOfWork
{
    private readonly AthleteDbContext _dbContext;

    public AthleteUnitOfWork(
        AthleteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default)
    {
        return _dbContext.SaveChangesAsync(
            cancellationToken);
    }
}