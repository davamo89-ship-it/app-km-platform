using System.Data;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace AppKm.Athletes.Infrastructure.Persistence;

internal sealed class AthleteUnitOfWork
    : IAthleteUnitOfWork
{
    private const int MaxSerializableAttempts = 4;

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

    public async Task<T> ExecuteSerializableAsync<T>(
        Func<CancellationToken, Task<T>> operation,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(operation);

        for (int attempt = 1; ; attempt++)
        {
            await using var transaction =
                await _dbContext.Database.BeginTransactionAsync(
                    IsolationLevel.Serializable,
                    cancellationToken);

            try
            {
                T result =
                    await operation(cancellationToken);

                await transaction.CommitAsync(
                    cancellationToken);

                return result;
            }
            catch (Exception exception)
                when (attempt < MaxSerializableAttempts &&
                      IsSerializationFailure(exception))
            {
                try
                {
                    await transaction.RollbackAsync(
                        cancellationToken);
                }
                catch
                {
                    // Preserve the original PostgreSQL concurrency failure.
                }

                _dbContext.ChangeTracker.Clear();

                await Task.Delay(
                    TimeSpan.FromMilliseconds(25 * attempt),
                    cancellationToken);
            }
        }
    }

    private static bool IsSerializationFailure(
        Exception exception)
    {
        if (exception is PostgresException postgresException)
        {
            return postgresException.SqlState is
                PostgresErrorCodes.SerializationFailure or
                PostgresErrorCodes.DeadlockDetected;
        }

        return exception.InnerException is not null &&
               IsSerializationFailure(
                   exception.InnerException);
    }
}
