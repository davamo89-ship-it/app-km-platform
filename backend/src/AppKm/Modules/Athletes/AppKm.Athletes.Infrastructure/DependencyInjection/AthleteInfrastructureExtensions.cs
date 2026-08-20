using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Infrastructure.Persistence;
using AppKm.Athletes.Infrastructure.Persistence.Repositories;
using AppKm.Athletes.Infrastructure.Integration;
using AppKm.Identity.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Platform.SharedKernel.Abstractions;
using AppKm.Athletes.Infrastructure.Strava;
using AppKm.Athletes.Application.Queries.GetStravaActivities;
using AppKm.Athletes.Application.Commands.SyncStravaActivities;
using AppKm.Athletes.Application.Queries.GetPointBalance;
using AppKm.Athletes.Application.Queries.GetPointHistory;
using AppKm.Athletes.Application.Queries.GetUpcomingPointExpirations;
using AppKm.Athletes.Application.Points;
using AppKm.Athletes.Application.Commands.ExpirePoints;

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

        services.AddScoped<GetStravaActivitiesQueryHandler>();
        services.AddScoped<SyncStravaActivitiesCommandHandler>();
        services.AddScoped<IPointTransactionRepository, PointTransactionRepository>();
        services.AddScoped<GetPointBalanceQueryHandler>();
        services.AddScoped<GetPointHistoryQueryHandler>();
        services.AddScoped<GetUpcomingPointExpirationsQueryHandler>();
        services.AddScoped<PointExpirationService>();
        

        services.Configure<StravaOptions>(
            configuration.GetSection(
                StravaOptions.SectionName));

        services.AddDataProtection();

        services.AddScoped<
            IStravaTokenProtector,
              StravaTokenProtector>();

        services.AddScoped<
            IStravaAuthorizationService,
            StravaAuthorizationService>();

        services.AddScoped<
            IStravaConnectionRepository,
            StravaConnectionRepository>();

        services.AddHttpClient<
            IStravaOAuthClient,
            StravaOAuthClient>();

        services.AddHttpClient<
            IStravaTokenRevocationService,
            StravaTokenRevocationService>();

        services.AddScoped<
            IStravaAccessTokenService,
            StravaAccessTokenService>();

        services.AddHttpClient<
            IStravaActivitiesClient,
            StravaActivitiesClient>();

        services.AddSingleton<
            IStravaTokenProtector,
            StravaTokenProtector>();

            services.AddScoped<
            ExpireCurrentAthletePointsCommandHandler>();

        services.AddScoped<
             IAthleteUnitOfWork,
             AthleteUnitOfWork>();

        services.AddScoped<
            IAthleteProfileProvisioner,
            AthleteProfileProvisioner>();

        services.AddScoped<
            IOAuthStateGenerator,
            OAuthStateGenerator>();

        services.AddSingleton<
            IOAuthStateStore,
            InMemoryOAuthStateStore>();

        services.AddScoped<
            IAthleteActivityRepository,
            AthleteActivityRepository>();

        return services;
    }
}