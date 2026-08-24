using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;


namespace AppKm.Athletes.Application.Commands.RejectAthleteRedemption;

public sealed class RejectAthleteRedemptionCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public RejectAthleteRedemptionCommandHandler(
        IAthleteRepository athleteRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<RejectAthleteRedemptionResult>> HandleAsync(
        RejectAthleteRedemptionCommand command,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                command.UserId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<RejectAthleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        RedemptionRequest? request =
            await _redemptionRequestRepository.GetByCodeAsync(
                command.Code.Trim(),
                cancellationToken);

        if (request is null ||
            request.AthleteId != athlete.Id.Value)
        {
            return Result<RejectAthleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.NotFound",
                    "Redemption request was not found."));
        }

        if (request.Status !=
            RedemptionRequestStatus.AwaitingAthleteConfirmation)
        {
            return Result<RejectAthleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.NotAwaitingConfirmation",
                    "The redemption request is not awaiting athlete confirmation."));
        }

        DateTimeOffset now =
            DateTimeOffset.UtcNow;

        request.RejectByAthlete(now);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<RejectAthleteRedemptionResult>.Success(
            new RejectAthleteRedemptionResult(
                request.Id.Value,
                request.Code,
                request.Status.ToString(),
                now));
    }
}