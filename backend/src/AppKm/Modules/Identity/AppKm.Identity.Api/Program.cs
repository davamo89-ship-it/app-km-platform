using AppKm.Identity.Infrastructure.DependencyInjection;
using AppKm.Identity.Application.Commands.RegisterUser;
using AppKm.Identity.Application.Commands.LoginUser;
using System.Text;
using AppKm.Identity.Infrastructure.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddIdentityInfrastructure(
    builder.Configuration);
builder.Services.AddScoped<RegisterUserCommandHandler>();
builder.Services.AddScoped<LoginUserCommandHandler>();
// Servicios HTTP
builder.Services.AddControllers();

// Documentación OpenAPI para desarrollo
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
                ClockSkew = TimeSpan.Zero
            };
    });

builder.Services.AddAuthorization();

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