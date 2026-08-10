using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.ConnectStrava;

public sealed class ConnectStravaCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IStravaConnectionRepository
        _connectionRepository;
    private readonly IStravaOAuthClient _oauthClient;
    private readonly IStravaTokenProtector _tokenProtector;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public ConnectStravaCommandHandler(
        IAthleteRepository athleteRepository,
        IStravaConnectionRepository connectionRepository,
        IStravaOAuthClient oauthClient,
        IStravaTokenProtector tokenProtector,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _connectionRepository = connectionRepository;
        _oauthClient = oauthClient;
        _tokenProtector = tokenProtector;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<ConnectStravaResult>> HandleAsync(
        ConnectStravaCommand command,
        CancellationToken cancellationToken)
    {
        var athlete =
            await _athleteRepository.GetByUserIdAsync(
                command.UserId,
                cancellationToken);

        if (athlete is null)
        {
            throw new InvalidOperationException(
                "Athlete profile was not found.");
        }

        StravaTokenExchangeResult tokens =
            await _oauthClient.ExchangeCodeAsync(
                command.AuthorizationCode,
                cancellationToken);

        string accessTokenEncrypted =
            _tokenProtector.Protect(
                tokens.AccessToken);

        string refreshTokenEncrypted =
            _tokenProtector.Protect(
                tokens.RefreshToken);

        DateTimeOffset utcNow =
            DateTimeOffset.UtcNow;

        StravaConnection? existing =
            await _connectionRepository
                .GetByAthleteIdAsync(
                    athlete.Id.Value,
                    cancellationToken);

        if (existing is null)
        {
            var connection =
                StravaConnection.Create(
                    StravaConnectionId.New(),
                    athlete.Id.Value,
                    tokens.StravaAthleteId,
                    accessTokenEncrypted,
                    refreshTokenEncrypted,
                    tokens.AccessTokenExpiresAtUtc,
                    utcNow);

            await _connectionRepository.AddAsync(
                connection,
                cancellationToken);
        }
        else
        {
            if (existing.StravaAthleteId !=
                tokens.StravaAthleteId)
            {
                throw new InvalidOperationException(
                    "This App KM athlete is already linked to another Strava account.");
            }

            existing.RotateTokens(
                accessTokenEncrypted,
                refreshTokenEncrypted,
                tokens.AccessTokenExpiresAtUtc,
                utcNow);
        }

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<ConnectStravaResult>.Success(
            new ConnectStravaResult(
                tokens.StravaAthleteId,
                utcNow));
    }
}