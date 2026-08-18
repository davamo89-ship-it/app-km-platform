using System.Net.Http.Json;
using System.Text.Json.Serialization;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.Extensions.Options;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class StravaOAuthClient
    : IStravaOAuthClient
{


    private readonly HttpClient _httpClient;
    private readonly StravaOptions _options;

    public StravaOAuthClient(
        HttpClient httpClient,
        IOptions<StravaOptions> options)
    {
        _httpClient = httpClient;
        _options = options.Value;
    }

    public async Task<StravaTokenExchangeResult> ExchangeCodeAsync(
        string code,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(code);

        var form = new Dictionary<string, string>
        {
            ["client_id"] =
                _options.ClientId.ToString(),

            ["client_secret"] =
                _options.ClientSecret,

            ["code"] =
                code,

            ["grant_type"] =
                "authorization_code"
        };

        var tokenEndpoint =
            $"{_options.OAuthBaseUrl.TrimEnd('/')}/token";

        using var request =
            new HttpRequestMessage(
                HttpMethod.Post,
                tokenEndpoint)
            {
                Content =
                    new FormUrlEncodedContent(form)
            };

        using HttpResponseMessage response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        response.EnsureSuccessStatusCode();

        StravaTokenResponse? tokenResponse =
            await response.Content
                .ReadFromJsonAsync<StravaTokenResponse>(
                    cancellationToken:
                        cancellationToken);

        if (tokenResponse is null)
        {
            throw new InvalidOperationException(
                "Strava returned an empty OAuth response.");
        }

        return new StravaTokenExchangeResult(
            tokenResponse.Athlete.Id,
            tokenResponse.AccessToken,
            tokenResponse.RefreshToken,
            DateTimeOffset.FromUnixTimeSeconds(
                tokenResponse.ExpiresAt));
    }

        public async Task<StravaTokenRefreshResult> RefreshTokenAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(refreshToken);

        var form = new Dictionary<string, string>
        {
            ["client_id"] =
                _options.ClientId.ToString(),

            ["client_secret"] =
                _options.ClientSecret,

            ["grant_type"] =
                "refresh_token",

            ["refresh_token"] =
                refreshToken
        };

        var tokenEndpoint =
            $"{_options.OAuthBaseUrl.TrimEnd('/')}/token";

        using var request =
            new HttpRequestMessage(
                HttpMethod.Post,
                tokenEndpoint)
            {
                Content =
                    new FormUrlEncodedContent(form)
            };

        using HttpResponseMessage response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        response.EnsureSuccessStatusCode();

        StravaRefreshTokenResponse? tokenResponse =
            await response.Content
                .ReadFromJsonAsync<StravaRefreshTokenResponse>(
                    cancellationToken:
                        cancellationToken);

        if (tokenResponse is null)
        {
            throw new InvalidOperationException(
                "Strava returned an empty token refresh response.");
        }

        return new StravaTokenRefreshResult(
            tokenResponse.AccessToken,
            tokenResponse.RefreshToken,
            DateTimeOffset.FromUnixTimeSeconds(
                tokenResponse.ExpiresAt));
    }

    private sealed record StravaTokenResponse(
        [property: JsonPropertyName("access_token")]
        string AccessToken,

        [property: JsonPropertyName("refresh_token")]
        string RefreshToken,

        [property: JsonPropertyName("expires_at")]
        long ExpiresAt,

        [property: JsonPropertyName("athlete")]
        StravaAthleteResponse Athlete);

    private sealed record StravaAthleteResponse(
        [property: JsonPropertyName("id")]
        long Id);
     private sealed record StravaRefreshTokenResponse(
        [property: JsonPropertyName("access_token")]
        string AccessToken,

        [property: JsonPropertyName("refresh_token")]
        string RefreshToken,

        [property: JsonPropertyName("expires_at")]
        long ExpiresAt);
}