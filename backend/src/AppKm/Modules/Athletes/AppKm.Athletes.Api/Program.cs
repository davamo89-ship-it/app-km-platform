using System.Diagnostics;
using System.IdentityModel.Tokens.Jwt;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using System.Text;
using AppKm.Athletes.Application.Queries.GetCurrentAthlete;
using AppKm.Athletes.Api.Realtime;
using AppKm.Athletes.Infrastructure.DependencyInjection;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using AppKm.Athletes.Application.Commands.UpdateAthleteProfile;
using AppKm.Athletes.Application.Commands.ConnectStrava;
using AppKm.Athletes.Application.Queries.GetStravaConnectionStatus;
using AppKm.Athletes.Application.Commands.DisconnectStrava;


var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(options =>
{
    options.AddServerHeader = false;
});

if (!builder.Environment.IsDevelopment())
{
    string? allowedHosts =
        builder.Configuration["AllowedHosts"];

    if (string.IsNullOrWhiteSpace(allowedHosts) ||
        allowedHosts.Trim() == "*" ||
        allowedHosts.StartsWith("REPLACE_", StringComparison.OrdinalIgnoreCase))
    {
        throw new InvalidOperationException(
            "Production configuration requires an explicit AllowedHosts value.");
    }

    string? productionAthleteDatabase =
        builder.Configuration.GetConnectionString("AthleteDatabase");

    string? productionIdentityDatabase =
        builder.Configuration.GetConnectionString("IdentityDatabase");

    string? productionJwtSecret =
        builder.Configuration["Jwt:Secret"];

    string? productionFirebaseProjectId =
        builder.Configuration["Firebase:ProjectId"];

    if (string.IsNullOrWhiteSpace(productionAthleteDatabase))
    {
        throw new InvalidOperationException(
            "Production configuration requires ConnectionStrings:AthleteDatabase.");
    }

    if (string.IsNullOrWhiteSpace(productionIdentityDatabase))
    {
        throw new InvalidOperationException(
            "Production configuration requires ConnectionStrings:IdentityDatabase.");
    }

    if (string.IsNullOrWhiteSpace(productionJwtSecret))
    {
        throw new InvalidOperationException(
            "Production configuration requires Jwt:Secret.");
    }

    if (Encoding.UTF8.GetByteCount(productionJwtSecret) < 32)
    {
        throw new InvalidOperationException(
            "Production Jwt:Secret must contain at least 32 UTF-8 bytes.");
    }

    string? productionJwtIssuer =
        builder.Configuration["Jwt:Issuer"];

    string? productionJwtAudience =
        builder.Configuration["Jwt:Audience"];

    if (string.IsNullOrWhiteSpace(productionJwtIssuer))
    {
        throw new InvalidOperationException(
            "Production configuration requires Jwt:Issuer.");
    }

    if (string.IsNullOrWhiteSpace(productionJwtAudience))
    {
        throw new InvalidOperationException(
            "Production configuration requires Jwt:Audience.");
    }

    if (string.IsNullOrWhiteSpace(productionFirebaseProjectId) ||
        productionFirebaseProjectId.StartsWith(
            "REPLACE_",
            StringComparison.OrdinalIgnoreCase))
    {
        throw new InvalidOperationException(
            "Production configuration requires Firebase:ProjectId.");
    }

    string? stravaClientId =
        builder.Configuration["Strava:ClientId"];

    string? stravaClientSecret =
        builder.Configuration["Strava:ClientSecret"];

    string? stravaRedirectUri =
        builder.Configuration["Strava:RedirectUri"];

    if (string.IsNullOrWhiteSpace(stravaClientId) ||
        stravaClientId == "0" ||
        stravaClientId.StartsWith(
            "REPLACE_",
            StringComparison.OrdinalIgnoreCase))
    {
        throw new InvalidOperationException(
            "Production configuration requires a valid Strava:ClientId.");
    }

    if (string.IsNullOrWhiteSpace(stravaClientSecret) ||
        stravaClientSecret.StartsWith(
            "REPLACE_",
            StringComparison.OrdinalIgnoreCase))
    {
        throw new InvalidOperationException(
            "Production configuration requires Strava:ClientSecret.");
    }

    if (string.IsNullOrWhiteSpace(stravaRedirectUri) ||
        stravaRedirectUri.Contains(
            "REPLACE_",
            StringComparison.OrdinalIgnoreCase) ||
        !Uri.TryCreate(stravaRedirectUri, UriKind.Absolute, out Uri? parsedStravaRedirectUri) ||
        parsedStravaRedirectUri.Scheme != Uri.UriSchemeHttps)
    {
        throw new InvalidOperationException(
            "Production Strava:RedirectUri must be an absolute HTTPS URL.");
    }
}

string athleteDatabaseConnectionString =
    builder.Configuration.GetConnectionString("AthleteDatabase")
    ?? throw new InvalidOperationException(
        "The AthleteDatabase connection string is missing.");

string identityDatabaseConnectionString =
    builder.Configuration.GetConnectionString("IdentityDatabase")
    ?? throw new InvalidOperationException(
        "The IdentityDatabase connection string is missing.");

string firebaseProjectId =
    builder.Configuration["Firebase:ProjectId"]
    ?? throw new InvalidOperationException(
        "Firebase:ProjectId is missing.");

_ = athleteDatabaseConnectionString;
_ = identityDatabaseConnectionString;
_ = firebaseProjectId;

builder.Services.AddAthleteInfrastructure(
    builder.Configuration);

builder.Services.AddScoped<GetCurrentAthleteQueryHandler>();
builder.Services.AddScoped<UpdateAthleteProfileCommandHandler>();
builder.Services.AddScoped<ConnectStravaCommandHandler>();
builder.Services.AddScoped<GetStravaConnectionStatusQueryHandler>();
builder.Services.AddScoped<DisconnectStravaCommandHandler>();


builder.Services.AddControllers();
builder.Services.AddProblemDetails();

builder.Services.AddHsts(options =>
{
    options.MaxAge = TimeSpan.FromDays(30);
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode =
        StatusCodes.Status429TooManyRequests;

    options.AddPolicy(
        "redemption-write",
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

    options.AddPolicy(
        "redemption-validate",
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
                        PermitLimit = 60,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0,
                        AutoReplenishment = true
                    });
        });
});
builder.Services.AddSignalR();

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
            Description = "Ingrese únicamente el access token JWT."
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

string issuer =
    builder.Configuration["Jwt:Issuer"]
    ?? throw new InvalidOperationException(
        "JWT issuer is missing.");

string audience =
    builder.Configuration["Jwt:Audience"]
    ?? throw new InvalidOperationException(
        "JWT audience is missing.");

string secret =
    builder.Configuration["Jwt:Secret"]
    ?? throw new InvalidOperationException(
        "JWT secret is missing.");

builder.Services
    .AddAuthentication(
        JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;

        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = issuer,

                ValidateAudience = true,
                ValidAudience = audience,

                ValidateIssuerSigningKey = true,
                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(secret)),

                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero,

                RoleClaimType = "role"
            };

        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                string? accessToken =
                    context.Request.Query["access_token"];

                PathString path = context.HttpContext.Request.Path;

                if (!string.IsNullOrWhiteSpace(accessToken) &&
                    path.StartsWithSegments(RedemptionHub.Path))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

builder.Services
    .AddHealthChecks()
    .AddNpgSql(
        athleteDatabaseConnectionString,
        name: "athletes-postgresql")
    .AddNpgSql(
        identityDatabaseConnectionString,
        name: "identity-postgresql");

var app = builder.Build();

ILogger requestLogger =
    app.Services
        .GetRequiredService<ILoggerFactory>()
        .CreateLogger("AppKm.Request");

app.Use(async (context, next) =>
{
    string correlationId =
        context.TraceIdentifier;

    context.Response.Headers["X-Correlation-ID"] =
        correlationId;

    var stopwatch =
        Stopwatch.StartNew();

    using IDisposable? scope =
        requestLogger.BeginScope(
            new Dictionary<string, object?>
            {
                ["CorrelationId"] = correlationId,
                ["Service"] = "AppKm.Athletes.Api",
                ["RequestMethod"] = context.Request.Method,
                ["RequestPath"] = context.Request.Path.Value ?? "/"
            });

    try
    {
        await next();
    }
    finally
    {
        stopwatch.Stop();

        requestLogger.LogInformation(
            "HTTP {RequestMethod} {RequestPath} responded {StatusCode} " +
            "in {ElapsedMilliseconds} ms. CorrelationId={CorrelationId}",
            context.Request.Method,
            context.Request.Path.Value ?? "/",
            context.Response.StatusCode,
            stopwatch.Elapsed.TotalMilliseconds,
            correlationId);
    }
});

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseExceptionHandler();

app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "DENY";
    await next();
});

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");
app.MapHub<RedemptionHub>(RedemptionHub.Path);

app.Run();
