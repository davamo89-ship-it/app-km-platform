using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace AppKm.Identity.Api.Security;

internal static class CognitoAuthentication
{
    public static bool IsConfigured(IConfiguration configuration)
    {
        return
            !string.IsNullOrWhiteSpace(configuration["Cognito:Region"]) &&
            !string.IsNullOrWhiteSpace(configuration["Cognito:UserPoolId"]) &&
            !string.IsNullOrWhiteSpace(configuration["Cognito:AppClientId"]);
    }

    public static void Configure(
        JwtBearerOptions options,
        IConfiguration configuration,
        PathString? signalRHubPath = null)
    {
        string region = Require(configuration, "Cognito:Region");
        string userPoolId = Require(configuration, "Cognito:UserPoolId");
        string appClientId = Require(configuration, "Cognito:AppClientId");
        string issuer = $"https://cognito-idp.{region}.amazonaws.com/{userPoolId}";

        options.MapInboundClaims = false;
        options.IncludeErrorDetails = false;
        options.Authority = issuer;
        options.RequireHttpsMetadata = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = issuer,
            ValidateAudience = false,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
            RoleClaimType = "role",
            NameClaimType = JwtRegisteredClaimNames.Sub
        };

        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                if (signalRHubPath.HasValue)
                {
                    string? accessToken = context.Request.Query["access_token"];
                    if (!string.IsNullOrWhiteSpace(accessToken) &&
                        context.HttpContext.Request.Path.StartsWithSegments(signalRHubPath.Value))
                    {
                        context.Token = accessToken;
                    }
                }

                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                ClaimsIdentity? identity = context.Principal?.Identity as ClaimsIdentity;
                if (identity is null)
                {
                    context.Fail("Cognito principal is missing.");
                    return Task.CompletedTask;
                }

                string? tokenUse = identity.FindFirst("token_use")?.Value;
                string? clientId = identity.FindFirst("client_id")?.Value;
                string? cognitoSubject = identity.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (!string.Equals(tokenUse, "access", StringComparison.Ordinal))
                {
                    context.Fail("Only Cognito access tokens are accepted.");
                    return Task.CompletedTask;
                }

                if (!string.Equals(clientId, appClientId, StringComparison.Ordinal))
                {
                    context.Fail("The Cognito app client does not match App KM.");
                    return Task.CompletedTask;
                }

                if (string.IsNullOrWhiteSpace(cognitoSubject))
                {
                    context.Fail("The Cognito subject is missing.");
                    return Task.CompletedTask;
                }

                // Preserve the provider identifier and expose a deterministic
                // App KM Guid through the existing `sub` contract. This keeps
                // the current domain/API surface stable during the AWS cutover.
                identity.AddClaim(new Claim("cognito_sub", cognitoSubject));
                foreach (Claim claim in identity.FindAll(JwtRegisteredClaimNames.Sub).ToArray())
                {
                    identity.RemoveClaim(claim);
                }
                identity.AddClaim(new Claim(
                    JwtRegisteredClaimNames.Sub,
                    ToAppKmUserId(cognitoSubject).ToString("D")));

                foreach (string group in ReadGroups(identity))
                {
                    if (!identity.HasClaim("role", group))
                    {
                        identity.AddClaim(new Claim("role", group));
                    }
                }

                return Task.CompletedTask;
            }
        };
    }

    private static IEnumerable<string> ReadGroups(ClaimsIdentity identity)
    {
        foreach (Claim claim in identity.FindAll("cognito:groups"))
        {
            string value = claim.Value.Trim();
            if (string.IsNullOrWhiteSpace(value))
            {
                continue;
            }

            if (value.StartsWith("[", StringComparison.Ordinal))
            {
                JsonDocument? document = null;
                try
                {
                    document = JsonDocument.Parse(value);
                    foreach (JsonElement item in document.RootElement.EnumerateArray())
                    {
                        string? group = item.GetString();
                        if (!string.IsNullOrWhiteSpace(group))
                        {
                            yield return group.Trim();
                        }
                    }
                }
                finally
                {
                    document?.Dispose();
                }
            }
            else
            {
                yield return value;
            }
        }
    }

    private static Guid ToAppKmUserId(string cognitoSubject)
    {
        byte[] hash = SHA256.HashData(Encoding.UTF8.GetBytes(cognitoSubject));
        Span<byte> guidBytes = stackalloc byte[16];
        hash.AsSpan(0, 16).CopyTo(guidBytes);
        return new Guid(guidBytes);
    }

    private static string Require(IConfiguration configuration, string key)
    {
        return configuration[key]
            ?? throw new InvalidOperationException($"{key} is required for Cognito authentication.");
    }
}
