using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Infrastructure.Persistence;
using AppKm.Athletes.Infrastructure.Persistence.Repositories;
using AppKm.Athletes.Infrastructure.Integration;
using AppKm.Identity.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Platform.SharedKernel.Abstractions;

namespace AppKm.Athletes.Infrastructure.DependencyInjection;

public static class AthleteInfrastructureExtensions
{
    public static IServiceCollection AddAthleteInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        string connectionString =
            configuration.GetConnectionString(
                "AthleteDatabase")
            ?? throw new InvalidOperationException(
                "The AthleteDatabase connection string is missing.");

        services.AddDbContext<AthleteDbContext>(
            options =>
                options.UseNpgsql(connectionString));

        services.AddScoped<
            IAthleteRepository,
            AthleteRepository>();

        services.AddScoped<
             IAthleteUnitOfWork,
             AthleteUnitOfWork>();

        services.AddScoped<
            IAthleteProfileProvisioner,
            AthleteProfileProvisioner>();

        return services;
    }
}