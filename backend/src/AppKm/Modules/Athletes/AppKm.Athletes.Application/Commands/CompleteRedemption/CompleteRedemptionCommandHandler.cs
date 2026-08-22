using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.PointTransactions;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.CompleteRedemption;

public sealed class CompleteRedemptionCommandHandler
{
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IPointTransactionRepository _pointTransactionRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public CompleteRedemptionCommandHandler(
        IRedemptionRequestRepository redemptionRequestRepository,
        IPointTransactionRepository pointTransactionRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _redemptionRequestRepository = redemptionRequestRepository;
        _pointTransactionRepository = pointTransactionRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<CompleteRedemptionResult>> HandleAsync(
        CompleteRedemptionCommand command,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(command.Code))
        {
            return Result<CompleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.InvalidCode",
                    "Redemption code is required."));
        }

        RedemptionRequest? request =
            await _redemptionRequestRepository.GetByCodeAsync(
                command.Code.Trim(),
                cancellationToken);

        if (request is null)
        {
            return Result<CompleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.NotFound",
                    "Redemption request was not found."));
        }

        if (request.Status != RedemptionRequestStatus.Pending)
        {
            return Result<CompleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.NotPending",
                    "The redemption request is no longer pending."));
        }

        DateTimeOffset now =
            DateTimeOffset.UtcNow;

        if (now > request.ExpiresAtUtc)
        {
            return Result<CompleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.Expired",
                    "The redemption request has expired."));
        }

        int balance =
            await _pointTransactionRepository.GetBalanceAsync(
                request.AthleteId,
                cancellationToken);

        if (request.RequestedPoints > balance)
        {
            return Result<CompleteRedemptionResult>.Failure(
                new Error(
                    "Athletes.Redemption.InsufficientBalance",
                    "The athlete does not have enough points."));
        }

        PointTransaction redeemed =
            PointTransaction.CreateRedeemed(
                request.AthleteId,
                request.RequestedPoints,
                now);

        await _pointTransactionRepository.AddAsync(
            redeemed,
            cancellationToken);

        request.Complete(now);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<CompleteRedemptionResult>.Success(
            new CompleteRedemptionResult(
                request.Id.Value,
                request.Code,
                request.RequestedPoints,
                request.Status.ToString(),
                request.CompletedAtUtc!.Value));
    }
}