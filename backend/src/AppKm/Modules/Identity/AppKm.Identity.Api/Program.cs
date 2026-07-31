var builder = WebApplication.CreateBuilder(args);

// Servicios HTTP
builder.Services.AddControllers();

// Documentación OpenAPI para desarrollo
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Supervisión básica de la aplicación
builder.Services.AddHealthChecks();

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