using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetPointHistory;

public sealed class GetPointHistoryQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IPointTransactionRepository
        _pointTransactionRepository;

    public GetPointHistoryQueryHandler(
        IAthleteRepository athleteRepository,
        IPointTransactionRepository pointTransactionRepository)
    {
        _athleteRepository = athleteRepository;
        _pointTransactionRepository =
            pointTransactionRepository;
    }

    public async Task<Result<IReadOnlyList<GetPointHistoryItem>>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<IReadOnlyList<GetPointHistoryItem>>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        var transactions =
            await _pointTransactionRepository.GetHistoryAsync(
                athlete.Id.Value,
                cancellationToken);

        var items =
            transactions
                .Select(transaction =>
                    new GetPointHistoryItem(
                        transaction.Type.ToString(),
                        transaction.Points,
                        transaction.CreatedAtUtc,
                        transaction.ExpiresAtUtc))
                .ToList();

        return Result<IReadOnlyList<GetPointHistoryItem>>.Success(
            items);
    }
}