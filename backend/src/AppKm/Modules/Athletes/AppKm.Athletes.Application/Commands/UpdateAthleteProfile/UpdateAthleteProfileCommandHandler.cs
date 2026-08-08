using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Results;


namespace AppKm.Athletes.Application.Commands.UpdateAthleteProfile;

public sealed class UpdateAthleteProfileCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public UpdateAthleteProfileCommandHandler(
        IAthleteRepository athleteRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<UpdateAthleteProfileResult>> HandleAsync(
        UpdateAthleteProfileCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                command.UserId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<UpdateAthleteProfileResult>.Failure(
                UpdateAthleteProfileErrors.NotFound);
        }

        DateTimeOffset utcNow = DateTimeOffset.UtcNow;

        try
        {
            athlete.UpdateDisplayName(
                command.DisplayName,
                utcNow);
        }
        catch (ArgumentException)
        {
            return Result<UpdateAthleteProfileResult>.Failure(
                UpdateAthleteProfileErrors.InvalidDisplayName);
        }

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<UpdateAthleteProfileResult>.Success(
            new UpdateAthleteProfileResult(
                athlete.Id.Value,
                athlete.UserId,
                athlete.DisplayName,
                utcNow));
    }
}