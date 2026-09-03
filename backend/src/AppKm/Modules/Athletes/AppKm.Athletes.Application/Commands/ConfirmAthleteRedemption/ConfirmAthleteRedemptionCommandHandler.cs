using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.PointTransactions;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.ConfirmAthleteRedemption;

public sealed class ConfirmAthleteRedemptionCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IPointTransactionRepository _pointTransactionRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public ConfirmAthleteRedemptionCommandHandler(
        IAthleteRepository athleteRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IPointTransactionRepository pointTransactionRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _pointTransactionRepository = pointTransactionRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<ConfirmAthleteRedemptionResult>> HandleAsync(
        ConfirmAthleteRedemptionCommand command,
        CancellationToken cancellationToken)
    {
        Athlete? athlete = await _athleteRepository.GetByUserIdAsync(
            command.UserId,
            cancellationToken);

        if (athlete is null)
            return Result<ConfirmAthleteRedemptionResult>.Failure(
                new Error("Athletes.Profile.NotFound", "The athlete profile was not found."));

        RedemptionRequest? request = await _redemptionRequestRepository.GetByCodeAsync(
            command.Code.Trim(),
            cancellationToken);

        if (request is null || request.AthleteId != athlete.Id.Value)
            return Result<ConfirmAthleteRedemptionResult>.Failure(
                new Error("Athletes.Redemption.NotFound", "Redemption request was not found."));

        if (request.Status != RedemptionRequestStatus.AwaitingAthleteConfirmation)
            return Result<ConfirmAthleteRedemptionResult>.Failure(
                new Error("Athletes.Redemption.NotAwaitingConfirmation", "The redemption request is not awaiting athlete confirmation."));

        if (request.ProposedPoints is null || request.ProposedPoints <= 0)
            return Result<ConfirmAthleteRedemptionResult>.Failure(
                new Error("Athletes.Redemption.InvalidProposal", "The redemption proposal is invalid."));

        DateTimeOffset now = DateTimeOffset.UtcNow;

        if (now > request.ExpiresAtUtc)
        {
            request.Expire(now);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result<ConfirmAthleteRedemptionResult>.Failure(
                new Error("Athletes.Redemption.Expired", "The redemption request has expired."));
        }

        int balance = await _pointTransactionRepository.GetBalanceAsync(
            athlete.Id.Value,
            cancellationToken);

        if (request.ProposedPoints.Value > balance)
            return Result<ConfirmAthleteRedemptionResult>.Failure(
                new Error("Athletes.Redemption.InsufficientBalance", "The athlete does not have enough points."));

        request.ConfirmByAthlete(now);

        PointTransaction redeemed = PointTransaction.CreateRedeemed(
            athlete.Id.Value,
            request.ProposedPoints.Value,
            now);

        await _pointTransactionRepository.AddAsync(
            redeemed,
            cancellationToken);

        request.Complete(now);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result<ConfirmAthleteRedemptionResult>.Success(
            new ConfirmAthleteRedemptionResult(
                request.Id.Value,
                request.Code,
                request.ProposedPoints.Value,
                request.Status.ToString(),
                request.AthleteConfirmedAtUtc!.Value,
                request.CompletedAtUtc!.Value));
    }
}
