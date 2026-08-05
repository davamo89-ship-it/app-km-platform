using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Infrastructure.Persistence;
using AppKm.Identity.Infrastructure.Persistence.Repositories;
using AppKm.Identity.Infrastructure.Security;
using AppKm.Identity.Infrastructure.Time;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Platform.SharedKernel.Abstractions;

namespace AppKm.Identity.Infrastructure.DependencyInjection;

public static class IdentityInfrastructureExtensions
{
    public static IServiceCollection AddIdentityInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        string connectionString =
            configuration.GetConnectionString("IdentityDatabase")
            ?? throw new InvalidOperationException(
                "The IdentityDatabase connection string is missing.");

        services.AddDbContext<IdentityDbContext>(
            options => options.UseNpgsql(connectionString));

        services.AddScoped<IUserRepository, UserRepository>();

        services.AddScoped<ISessionRepository, SessionRepository>();

        services.AddScoped<IUnitOfWork>(
            serviceProvider =>
                serviceProvider.GetRequiredService<IdentityDbContext>());

        services.AddSingleton<IPasswordHasher, PasswordHasherAdapter>();

        services.AddSingleton<IClock, SystemClock>();

        services.Configure<JwtOptions>(
            configuration.GetSection(JwtOptions.SectionName));

        services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();

        services.Configure<RefreshTokenOptions>(configuration.GetSection(RefreshTokenOptions.SectionName));

        services.AddSingleton<IRefreshTokenGenerator, RefreshTokenGenerator>();

        return services;
    }
}