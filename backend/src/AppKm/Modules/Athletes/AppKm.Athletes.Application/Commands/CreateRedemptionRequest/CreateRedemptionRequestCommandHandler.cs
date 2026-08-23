using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.CreateRedemptionRequest;

public sealed class CreateRedemptionRequestCommandHandler
{
    private static readonly TimeSpan CodeLifetime =
        TimeSpan.FromMinutes(5);

    private readonly IAthleteRepository _athleteRepository;
    private readonly IPointTransactionRepository _pointTransactionRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IRedemptionCodeGenerator _codeGenerator;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public CreateRedemptionRequestCommandHandler(
        IAthleteRepository athleteRepository,
        IPointTransactionRepository pointTransactionRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IRedemptionCodeGenerator codeGenerator,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _pointTransactionRepository = pointTransactionRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _codeGenerator = codeGenerator;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<CreateRedemptionRequestResult>> HandleAsync(
        CreateRedemptionRequestCommand command,
        CancellationToken cancellationToken)
    {
        if (command.RequestedPoints <= 0)
        {
            return Result<CreateRedemptionRequestResult>.Failure(
                new Error(
                    "Athletes.Redemption.InvalidPoints",
                    "Requested points must be greater than zero."));
        }

        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                command.UserId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<CreateRedemptionRequestResult>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

       DateTimeOffset now =
           DateTimeOffset.UtcNow;

        int balance =
            await _pointTransactionRepository.GetBalanceAsync(
                athlete.Id.Value,
                cancellationToken);

        int reservedPoints =
            await _redemptionRequestRepository.GetPendingReservedPointsAsync(
                athlete.Id.Value,
                now,
                cancellationToken);

        int availableBalance =
            balance - reservedPoints;

        if (command.RequestedPoints > availableBalance)
        {
            return Result<CreateRedemptionRequestResult>.Failure(
                new Error(
                    "Athletes.Redemption.InsufficientAvailableBalance",
                    "The athlete does not have enough available points."));
        }

        string code;

        do
        {
            code = _codeGenerator.Generate();
        }
        while (await _redemptionRequestRepository.ExistsByCodeAsync(
            code,
            cancellationToken));       

        DateTimeOffset expiresAtUtc =
            now.Add(CodeLifetime);

        RedemptionRequest request =
            RedemptionRequest.Create(
                athlete.Id.Value,
                code,
                command.RequestedPoints,
                now,
                expiresAtUtc);

        await _redemptionRequestRepository.AddAsync(
            request,
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<CreateRedemptionRequestResult>.Success(
            new CreateRedemptionRequestResult(
                request.Id.Value,
                request.Code,
                request.RequestedPoints,
                request.Status.ToString(),
                request.CreatedAtUtc,
                request.ExpiresAtUtc));
    }
}