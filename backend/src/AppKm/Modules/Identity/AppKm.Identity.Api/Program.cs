using System.IdentityModel.Tokens.Jwt;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using AppKm.Identity.Infrastructure.DependencyInjection;
using AppKm.Identity.Application.Commands.RegisterUser;
using AppKm.Identity.Application.Commands.LoginUser;
using System.Text;
using AppKm.Identity.Infrastructure.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using AppKm.Identity.Application.Commands.RefreshSession;
using AppKm.Identity.Application.Commands.LogoutSession;
using AppKm.Identity.Application.Commands.RegisterPushDevice;
using AppKm.Identity.Application.Commands.DeactivatePushDevice;
using AppKm.Identity.Api.Security;
using AppKm.Identity.Domain.Aggregates.Roles;
using AppKm.Athletes.Infrastructure.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddIdentityInfrastructure(
    builder.Configuration);

builder.Services.AddAthleteInfrastructure(
    builder.Configuration);

builder.Services.AddScoped<RegisterUserCommandHandler>();
builder.Services.AddScoped<LoginUserCommandHandler>();
builder.Services.AddScoped<RefreshSessionCommandHandler>();
builder.Services.AddScoped<LogoutSessionCommandHandler>();
builder.Services.AddScoped<RegisterPushDeviceCommandHandler>();
builder.Services.AddScoped<DeactivatePushDeviceCommandHandler>();

// Servicios HTTP
builder.Services.AddControllers();

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode =
        StatusCodes.Status429TooManyRequests;

    options.AddPolicy(
        "identity-auth",
        context =>
            RateLimitPartition.GetFixedWindowLimiter(
                partitionKey:
                    context.Connection.RemoteIpAddress?.ToString()
                    ?? "unknown",
                factory: _ =>
                    new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = 10,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0,
                        AutoReplenishment = true
                    }));

    options.AddPolicy(
        "identity-refresh",
        context =>
            RateLimitPartition.GetFixedWindowLimiter(
                partitionKey:
                    context.Connection.RemoteIpAddress?.ToString()
                    ?? "unknown",
                factory: _ =>
                    new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = 30,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0,
                        AutoReplenishment = true
                    }));

    options.AddPolicy(
        "identity-device",
        context =>
        {
            string partitionKey =
                context.User
                    .FindFirst(JwtRegisteredClaimNames.Sub)
                    ?.Value
                ?? context.Connection.RemoteIpAddress?.ToString()
                ?? "unknown";

            return RateLimitPartition.GetFixedWindowLimiter(
                partitionKey,
                _ =>
                    new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = 30,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0,
                        AutoReplenishment = true
                    });
        });
});

// Documentación OpenAPI para desarrollo
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition(
        "Bearer",
        new OpenApiSecurityScheme
        {
            Name = "Authorization",
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            In = ParameterLocation.Header,
            Description =
                "Ingrese únicamente el access token JWT."
        });

    options.AddSecurityRequirement(
        new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "Bearer"
                    }
                },
                Array.Empty<string>()
            }
        });
});

JwtOptions jwtOptions =
    builder.Configuration
        .GetSection(JwtOptions.SectionName)
        .Get<JwtOptions>()
    ?? throw new InvalidOperationException(
        "The JWT configuration is missing.");

if (string.IsNullOrWhiteSpace(jwtOptions.Secret))
{
    throw new InvalidOperationException(
        "The JWT secret is missing.");
}

builder.Services
    .AddAuthentication(
        JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.IncludeErrorDetails = true;

        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = jwtOptions.Issuer,

                ValidateAudience = true,
                ValidAudience = jwtOptions.Audience,

                ValidateIssuerSigningKey = true,
                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(
                            jwtOptions.Secret)),

                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero,

                RoleClaimType = "role",
            };

        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                Console.WriteLine(
                    $"JWT authentication failed: " +
                    $"{context.Exception.GetType().Name} - " +
                    $"{context.Exception.Message}");

                return Task.CompletedTask;
            },

            OnTokenValidated = context =>
            {
                Console.WriteLine("JWT validated successfully.");

                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(
        AuthorizationPolicies.AthleteOnly,
        policy =>
        {
            policy.RequireAuthenticatedUser();
            policy.RequireRole(RoleNames.Athlete);
        });

    options.AddPolicy(
        AuthorizationPolicies.MerchantOnly,
        policy =>
        {
            policy.RequireAuthenticatedUser();
            policy.RequireRole(RoleNames.Merchant);
        });

    options.AddPolicy(
        AuthorizationPolicies.AdminOnly,
        policy =>
        {
            policy.RequireAuthenticatedUser();
            policy.RequireRole(RoleNames.Admin);
        });
});

// Supervisión básica de la aplicación
string identityConnectionString =
    builder.Configuration.GetConnectionString("IdentityDatabase")
    ?? throw new InvalidOperationException(
        "The IdentityDatabase connection string is missing.");

builder.Services
    .AddHealthChecks()
    .AddNpgSql(
        identityConnectionString,
        name: "identity-postgresql");

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();

app.MapControllers();

app.MapHealthChecks("/health");

app.MapGet(
        "/",
        () => Results.Ok(
            new
            {
                service = "AppKm.Identity.Api",
                status = "running",
                version = "v1"
            }))
    .ExcludeFromDescription();

app.Run();
