using AppKm.Athletes.Application.Interfaces;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Options;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class StravaAuthorizationService
    : IStravaAuthorizationService
{
    private const string AuthorizationEndpoint =
        "https://www.strava.com/oauth/authorize";

    private readonly StravaOptions _options;

    public StravaAuthorizationService(
        IOptions<StravaOptions> options)
    {
        _options = options.Value;
    }

    public string BuildAuthorizationUrl(
        string state)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(state);

        var parameters =
            new Dictionary<string, string?>
            {
                ["client_id"] =
                    _options.ClientId.ToString(),

                ["redirect_uri"] =
                    _options.RedirectUri,

                ["response_type"] =
                    "code",

                ["approval_prompt"] =
                    "auto",

                ["scope"] =
                    "read,activity:read_all",

                ["state"] =
                    state
            };

        return QueryHelpers.AddQueryString(
            AuthorizationEndpoint,
            parameters);
    }
}