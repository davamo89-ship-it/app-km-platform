using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.CancelRedemption;

public sealed class CancelRedemptionCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public CancelRedemptionCommandHandler(
        IAthleteRepository athleteRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<CancelRedemptionResult>> HandleAsync(
        CancelRedemptionCommand command,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                command.UserId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<CancelRedemptionResult>.Failure(
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
            return Result<CancelRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.NotFound",
                    "Redemption request was not found."));
        }

        if (request.Status != RedemptionRequestStatus.Pending)
        {
            return Result<CancelRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.NotPending",
                    "The redemption request is no longer pending."));
        }

        request.Cancel();

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<CancelRedemptionResult>.Success(
            new CancelRedemptionResult(
                request.Id.Value,
                request.Code,
                request.Status.ToString()));
    }
}