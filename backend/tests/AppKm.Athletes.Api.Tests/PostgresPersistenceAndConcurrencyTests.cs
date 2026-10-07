using AppKm.Athletes.Application.Commands.ConfirmAthleteRedemption;
using AppKm.Athletes.Application.Commands.CreateRedemptionRequest;
using AppKm.Athletes.Application.Commands.ProposeMerchantRedemption;
using AppKm.Athletes.Domain.Activities;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.PointTransactions;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using AppKm.Athletes.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace AppKm.Athletes.Api.Tests;

public sealed class PostgresPersistenceAndConcurrencyTests
    : IClassFixture<PostgresAthletesFixture>
{
    private readonly PostgresAthletesFixture _fixture;

    public PostgresPersistenceAndConcurrencyTests(
        PostgresAthletesFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task Migrations_ApplyAgainstRealPostgres()
    {
        await _fixture.ResetAsync();

        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        string[] applied =
            (await dbContext.Database
                .GetAppliedMigrationsAsync())
            .ToArray();

        Assert.NotEmpty(applied);

        Assert.Contains(
            applied,
            migration =>
                migration.Contains(
                    "CreateAthleteModule",
                    StringComparison.Ordinal));

        Assert.Contains(
            applied,
            migration =>
                migration.Contains(
                    "AddRedemptionRequests",
                    StringComparison.Ordinal));
    }

    [Fact]
    public async Task CriticalRedemptionFlow_UsesRealPostgresAndUpdatesBalance()
    {
        await _fixture.ResetAsync();

        SeededActors actors =
            await SeedBalanceAndMerchantAsync(
                earnedPoints: 100);

        CreateRedemptionRequestResult createValue;

        await using (AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope())
        {
            CreateRedemptionRequestCommandHandler handler =
                scope.ServiceProvider
                    .GetRequiredService<CreateRedemptionRequestCommandHandler>();

            var createResult =
                await handler.HandleAsync(
                    new CreateRedemptionRequestCommand(
                        actors.AthleteUserId,
                        60),
                    CancellationToken.None);

            Assert.True(createResult.IsSuccess);

            createValue =
                createResult.Value;
        }

        string code =
            createValue.Code;

        await using (AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope())
        {
            ProposeMerchantRedemptionCommandHandler handler =
                scope.ServiceProvider
                    .GetRequiredService<ProposeMerchantRedemptionCommandHandler>();

            var proposeResult =
                await handler.HandleAsync(
                    new ProposeMerchantRedemptionCommand(
                        actors.MerchantUserId,
                        code,
                        60),
                    CancellationToken.None);

            Assert.True(proposeResult.IsSuccess);
        }

        await using (AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope())
        {
            ConfirmAthleteRedemptionCommandHandler handler =
                scope.ServiceProvider
                    .GetRequiredService<ConfirmAthleteRedemptionCommandHandler>();

            var confirmResult =
                await handler.HandleAsync(
                    new ConfirmAthleteRedemptionCommand(
                        actors.AthleteUserId,
                        code),
                    CancellationToken.None);

            Assert.True(confirmResult.IsSuccess);
        }

        int balance =
            await GetBalanceAsync(
                actors.AthleteId);

        Assert.Equal(
            40,
            balance);
    }

    [Fact]
    public async Task ConcurrentCreation_CannotReserveMoreThanAvailableBalance()
    {
        await _fixture.ResetAsync();

        SeededActors actors =
            await SeedBalanceAndMerchantAsync(
                earnedPoints: 100);

        Task<object> first =
            RunCreateAsync(
                actors.AthleteUserId,
                80);

        Task<object> second =
            RunCreateAsync(
                actors.AthleteUserId,
                80);

        object[] results =
            await Task.WhenAll(
                first,
                second);

        int successes =
            CountSuccessfulResults(
                results);

        Assert.Equal(
            1,
            successes);

        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        int activeReservations =
            await dbContext.RedemptionRequests
                .CountAsync(request =>
                    request.AthleteId == actors.AthleteId &&
                    (request.Status == RedemptionRequestStatus.Pending ||
                     request.Status ==
                        RedemptionRequestStatus.AwaitingAthleteConfirmation));

        Assert.Equal(
            1,
            activeReservations);
    }

    [Fact]
    public async Task ConcurrentConfirmation_OfSameRequest_RedeemsOnlyOnce()
    {
        await _fixture.ResetAsync();

        SeededActors actors =
            await SeedBalanceAndMerchantAsync(
                earnedPoints: 100);

        string code =
            await SeedAwaitingConfirmationAsync(
                actors,
                points: 60,
                code: "SAME60");

        Task<object> first =
            RunConfirmAsync(
                actors.AthleteUserId,
                code);

        Task<object> second =
            RunConfirmAsync(
                actors.AthleteUserId,
                code);

        object[] results =
            await Task.WhenAll(
                first,
                second);

        int successes =
            CountSuccessfulResults(
                results);

        Assert.Equal(
            1,
            successes);

        int balance =
            await GetBalanceAsync(
                actors.AthleteId);

        Assert.Equal(
            40,
            balance);

        int redeemedRows =
            await CountRedeemedTransactionsAsync(
                actors.AthleteId);

        Assert.Equal(
            1,
            redeemedRows);
    }

    [Fact]
    public async Task ConcurrentConfirmation_OfDifferentRequests_CannotOverspend()
    {
        await _fixture.ResetAsync();

        SeededActors actors =
            await SeedBalanceAndMerchantAsync(
                earnedPoints: 100);

        string firstCode =
            await SeedAwaitingConfirmationAsync(
                actors,
                points: 70,
                code: "FIRST70");

        string secondCode =
            await SeedAwaitingConfirmationAsync(
                actors,
                points: 70,
                code: "SECOND70");

        Task<object> first =
            RunConfirmAsync(
                actors.AthleteUserId,
                firstCode);

        Task<object> second =
            RunConfirmAsync(
                actors.AthleteUserId,
                secondCode);

        object[] results =
            await Task.WhenAll(
                first,
                second);

        int successes =
            CountSuccessfulResults(
                results);

        Assert.Equal(
            1,
            successes);

        int balance =
            await GetBalanceAsync(
                actors.AthleteId);

        Assert.Equal(
            30,
            balance);

        int redeemedRows =
            await CountRedeemedTransactionsAsync(
                actors.AthleteId);

        Assert.Equal(
            1,
            redeemedRows);
    }

    private static int CountSuccessfulResults(
        IEnumerable<object> results)
    {
        return results.Count(
            result =>
            {
                object? value =
                    result
                        .GetType()
                        .GetProperty("IsSuccess")?
                        .GetValue(result);

                return value is true;
            });
    }

    private async Task<SeededActors> SeedBalanceAndMerchantAsync(
        int earnedPoints)
    {
        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        DateTimeOffset now =
            DateTimeOffset.UtcNow;

        Guid athleteUserId =
            Guid.NewGuid();

        Athlete athlete =
            Athlete.Create(
                AthleteId.New(),
                athleteUserId,
                "Integration Athlete",
                now);

        Guid merchantUserId =
            Guid.NewGuid();

        Merchant merchant =
            Merchant.Create(
                merchantUserId,
                "Integration Merchant",
                now);

        AthleteActivity activity =
            AthleteActivity.Create(
                athlete.Id,
                Random.Shared.NextInt64(
                    1_000_000,
                    9_000_000),
                AppKmActivityType.Running,
                earnedPoints,
                earnedPoints,
                now,
                DateTime.SpecifyKind(
                    DateTime.Now,
                    DateTimeKind.Unspecified),
                3600,
                3600,
                now);

        PointTransaction earned =
            PointTransaction.CreateEarned(
                athlete.Id.Value,
                activity.Id.Value,
                earnedPoints,
                now);

        await dbContext.Athletes.AddAsync(
            athlete);

        await dbContext.Merchants.AddAsync(
            merchant);

        await dbContext.AthleteActivities.AddAsync(
            activity);

        await dbContext.PointTransactions.AddAsync(
            earned);

        await dbContext.SaveChangesAsync();

        return new SeededActors(
            athleteUserId,
            athlete.Id.Value,
            merchantUserId,
            merchant.Id.Value);
    }

    private async Task<string> SeedAwaitingConfirmationAsync(
        SeededActors actors,
        int points,
        string code)
    {
        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        DateTimeOffset now =
            DateTimeOffset.UtcNow;

        RedemptionRequest request =
            RedemptionRequest.Create(
                actors.AthleteId,
                code,
                points,
                now,
                now.AddMinutes(5));

        request.ProposeByMerchant(
            actors.MerchantId,
            points,
            now);

        await dbContext.RedemptionRequests.AddAsync(
            request);

        await dbContext.SaveChangesAsync();

        return request.Code;
    }

    private async Task<int> GetBalanceAsync(
        Guid athleteId)
    {
        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        int earned =
            await dbContext.PointTransactions
                .Where(transaction =>
                    transaction.AthleteId == athleteId &&
                    transaction.Type ==
                        PointTransactionType.Earned)
                .SumAsync(transaction =>
                    (int?)transaction.Points)
                ?? 0;

        int redeemed =
            await dbContext.PointTransactions
                .Where(transaction =>
                    transaction.AthleteId == athleteId &&
                    transaction.Type ==
                        PointTransactionType.Redeemed)
                .SumAsync(transaction =>
                    (int?)transaction.Points)
                ?? 0;

        int expired =
            await dbContext.PointTransactions
                .Where(transaction =>
                    transaction.AthleteId == athleteId &&
                    transaction.Type ==
                        PointTransactionType.Expired)
                .SumAsync(transaction =>
                    (int?)transaction.Points)
                ?? 0;

        return earned - redeemed - expired;
    }

    private async Task<int> CountRedeemedTransactionsAsync(
        Guid athleteId)
    {
        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        return await dbContext.PointTransactions
            .CountAsync(transaction =>
                transaction.AthleteId == athleteId &&
                transaction.Type ==
                    PointTransactionType.Redeemed);
    }

    private async Task<object> RunCreateAsync(
        Guid athleteUserId,
        int points)
    {
        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        CreateRedemptionRequestCommandHandler handler =
            scope.ServiceProvider
                .GetRequiredService<CreateRedemptionRequestCommandHandler>();

        return await handler.HandleAsync(
            new CreateRedemptionRequestCommand(
                athleteUserId,
                points),
            CancellationToken.None);
    }

    private async Task<object> RunConfirmAsync(
        Guid athleteUserId,
        string code)
    {
        await using AsyncServiceScope scope =
            _fixture.Services.CreateAsyncScope();

        ConfirmAthleteRedemptionCommandHandler handler =
            scope.ServiceProvider
                .GetRequiredService<ConfirmAthleteRedemptionCommandHandler>();

        return await handler.HandleAsync(
            new ConfirmAthleteRedemptionCommand(
                athleteUserId,
                code),
            CancellationToken.None);
    }

    private sealed record SeededActors(
        Guid AthleteUserId,
        Guid AthleteId,
        Guid MerchantUserId,
        Guid MerchantId);
}
