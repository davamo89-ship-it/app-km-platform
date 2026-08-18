using System.Net.Http.Headers;
using System.Text;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.Extensions.Options;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class StravaTokenRevocationService
    : IStravaTokenRevocationService
{
    private readonly HttpClient _httpClient;
    private readonly StravaOptions _options;
    private readonly IStravaTokenProtector _tokenProtector;

    public StravaTokenRevocationService(
        HttpClient httpClient,
        IOptions<StravaOptions> options,
        IStravaTokenProtector tokenProtector)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _tokenProtector = tokenProtector;
    }

    public async Task RevokeAsync(
        string protectedToken,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(protectedToken);

        string token =
            _tokenProtector.Unprotect(protectedToken);

        string revokeEndpoint =
            $"{_options.OAuthBaseUrl.TrimEnd('/')}/revoke";

        string credentials =
            $"{_options.ClientId}:{_options.ClientSecret}";

        string encodedCredentials =
            Convert.ToBase64String(
                Encoding.UTF8.GetBytes(credentials));

        using var request =
            new HttpRequestMessage(
                HttpMethod.Post,
                revokeEndpoint);

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Basic",
                encodedCredentials);

        request.Content =
            new FormUrlEncodedContent(
                new Dictionary<string, string>
                {
                    ["token"] = token
                });

        using HttpResponseMessage response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        response.EnsureSuccessStatusCode();
    }
}