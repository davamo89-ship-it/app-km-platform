using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Identity.Application.Interfaces;

namespace AppKm.Athletes.Infrastructure.Integration;

internal sealed class AthleteProfileProvisioner
    : IAthleteProfileProvisioner
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public AthleteProfileProvisioner(
        IAthleteRepository athleteRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task CreateAsync(
        Guid userId,
        string displayName,
        CancellationToken cancellationToken)
    {
        bool exists =
            await _athleteRepository.ExistsByUserIdAsync(
                userId,
                cancellationToken);

        if (exists)
        {
            return;
        }

        Athlete athlete = Athlete.Create(
            AthleteId.New(),
            userId,
            displayName,
            DateTimeOffset.UtcNow);

        await _athleteRepository.AddAsync(
            athlete,
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);
    }
}