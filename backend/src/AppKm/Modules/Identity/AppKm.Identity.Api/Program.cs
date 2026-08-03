using AppKm.Identity.Infrastructure.DependencyInjection;
using AppKm.Identity.Application.Commands.RegisterUser;
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddIdentityInfrastructure(
    builder.Configuration);
builder.Services.AddScoped<RegisterUserCommandHandler>();
// Servicios HTTP
builder.Services.AddControllers();

// Documentación OpenAPI para desarrollo
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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