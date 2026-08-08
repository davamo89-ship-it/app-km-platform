namespace AppKm.Athletes.Application.Interfaces;

public interface IAthleteUnitOfWork
{
    Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default);
}