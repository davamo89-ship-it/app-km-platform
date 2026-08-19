using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetPointBalance;

public sealed class GetPointBalanceQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IPointTransactionRepository
        _pointTransactionRepository;

    public GetPointBalanceQueryHandler(
        IAthleteRepository athleteRepository,
        IPointTransactionRepository pointTransactionRepository)
    {
        _athleteRepository = athleteRepository;
        _pointTransactionRepository =
            pointTransactionRepository;
    }

    public async Task<Result<GetPointBalanceResult>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<GetPointBalanceResult>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        int balance =
            await _pointTransactionRepository.GetBalanceAsync(
                athlete.Id.Value,
                cancellationToken);

        return Result<GetPointBalanceResult>.Success(
            new GetPointBalanceResult(balance));
    }
}