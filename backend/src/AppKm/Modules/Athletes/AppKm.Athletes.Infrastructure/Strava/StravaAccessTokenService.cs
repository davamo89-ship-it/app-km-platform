using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class StravaAccessTokenService
    : IStravaAccessTokenService
{
    private static readonly TimeSpan RefreshThreshold =
        TimeSpan.FromHours(1);

    private readonly IStravaOAuthClient _oauthClient;
    private readonly IStravaTokenProtector _tokenProtector;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public StravaAccessTokenService(
        IStravaOAuthClient oauthClient,
        IStravaTokenProtector tokenProtector,
        IAthleteUnitOfWork unitOfWork)
    {
        _oauthClient = oauthClient;
        _tokenProtector = tokenProtector;
        _unitOfWork = unitOfWork;
    }

    public async Task<string> GetValidAccessTokenAsync(
        StravaConnection connection,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(connection);

        DateTimeOffset now =
            DateTimeOffset.UtcNow;

        if (connection.AccessTokenExpiresAtUtc > now + RefreshThreshold)
        {
            return _tokenProtector.Unprotect(
                connection.AccessTokenEncrypted);
        }

        string refreshToken =
            _tokenProtector.Unprotect(
                connection.RefreshTokenEncrypted);

        StravaTokenRefreshResult refreshed =
            await _oauthClient.RefreshTokenAsync(
                refreshToken,
                cancellationToken);

        string accessTokenEncrypted =
            _tokenProtector.Protect(
                refreshed.AccessToken);

        string refreshTokenEncrypted =
            _tokenProtector.Protect(
                refreshed.RefreshToken);

        connection.RotateTokens(
            accessTokenEncrypted,
            refreshTokenEncrypted,
            refreshed.AccessTokenExpiresAtUtc,
            now);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return refreshed.AccessToken;
    }
}