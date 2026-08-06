using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Users;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Platform.SharedKernel.Abstractions;

namespace AppKm.Identity.Infrastructure.Security;

internal sealed class JwtTokenGenerator : IJwtTokenGenerator
{
    private readonly JwtOptions _options;
    private readonly IClock _clock;

    public JwtTokenGenerator(
        IOptions<JwtOptions> options,
        IClock clock)
    {
        _options = options.Value;
        _clock = clock;
    }

    public JwtTokenResult Generate(
        UserId userId,
        string email,
        IReadOnlyCollection<string> roles)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(email);
        ArgumentNullException.ThrowIfNull(roles);

        DateTimeOffset issuedAtUtc = _clock.UtcNow;
        DateTimeOffset expiresAtUtc =
            issuedAtUtc.AddMinutes(_options.ExpirationMinutes);

      var claims = new List<Claim>
        {
        new(
            JwtRegisteredClaimNames.Sub,
            userId.Value.ToString()),

        new(
            JwtRegisteredClaimNames.Email,
            email),

        new(
            JwtRegisteredClaimNames.Jti,
            Guid.NewGuid().ToString())
        };

        foreach (string role in roles)
        {
            claims.Add(
                new Claim(
                    "role",
                    role));
}

        var securityKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_options.Secret));

        var signingCredentials = new SigningCredentials(
            securityKey,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: issuedAtUtc.UtcDateTime,
            expires: expiresAtUtc.UtcDateTime,
            signingCredentials: signingCredentials);

        string encodedToken =
            new JwtSecurityTokenHandler().WriteToken(token);

        return new JwtTokenResult(
            encodedToken,
            expiresAtUtc);
    }
}