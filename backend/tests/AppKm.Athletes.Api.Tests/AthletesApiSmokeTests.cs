using System.Net;
using System.Net.Http.Json;
using Xunit;

namespace AppKm.Athletes.Api.Tests;

public sealed class AthletesApiSmokeTests
    : IClassFixture<AthletesApiFactory>
{
    private readonly HttpClient _client;

    public AthletesApiSmokeTests(AthletesApiFactory factory)
    {
        _client =
            factory.CreateClient(
                new Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactoryClientOptions
                {
                    AllowAutoRedirect = false
                });
    }

    [Fact]
    public async Task Health_ReturnsOkWithoutExternalDatabases()
    {
        HttpResponseMessage response =
            await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Theory]
    [InlineData("/api/v1/athletes/me")]
    [InlineData("/api/v1/athletes/dashboard")]
    [InlineData("/api/v1/athletes/activities")]
    [InlineData("/api/v1/athletes/settings")]
    [InlineData("/api/v1/athletes/points/balance")]
    [InlineData("/api/v1/athletes/points/history")]
    [InlineData("/api/v1/athletes/points/expirations")]
    [InlineData("/api/v1/athletes/redemptions")]
    [InlineData("/api/v1/athletes/redemptions/pending-confirmation")]
    [InlineData("/api/v1/athletes/redemptions/pending-confirmations")]
    [InlineData("/api/v1/athletes/strava/connect")]
    [InlineData("/api/v1/athletes/strava/status")]
    [InlineData("/api/v1/athletes/strava/activities")]
    [InlineData("/api/v1/merchants/me")]
    [InlineData("/api/v1/merchants/redemptions/latest")]
    [InlineData("/api/v1/merchants/redemptions/history")]
    [InlineData("/api/v1/admin/redemptions")]
    public async Task ProtectedGetRoutes_WithoutToken_ReturnUnauthorized(
        string path)
    {
        HttpResponseMessage response =
            await _client.GetAsync(path);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task ProtectedPatchRoute_WithoutToken_ReturnsUnauthorized()
    {
        using var request =
            new HttpRequestMessage(
                HttpMethod.Patch,
                "/api/v1/athletes/me")
            {
                Content =
                    JsonContent.Create(
                        new
                        {
                            displayName = "Test Athlete",
                            profileImageUrl = (string?)null,
                            countryCode = "CR",
                            birthDate = (string?)null,
                            preferredSport = "Running"
                        })
            };

        HttpResponseMessage response =
            await _client.SendAsync(request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task StravaCallback_WithoutCodeOrState_RedirectsToInvalidCallback()
    {
        HttpResponseMessage response =
            await _client.GetAsync(
                "/api/v1/athletes/strava/callback");

        Assert.Equal(
            HttpStatusCode.Redirect,
            response.StatusCode);

        Assert.NotNull(response.Headers.Location);

        Assert.Equal(
            "appkm://strava-callback/?status=invalid_callback",
            response.Headers.Location!.ToString());
    }

    [Fact]
    public async Task StravaCallback_WithDeniedError_RedirectsToDenied()
    {
        HttpResponseMessage response =
            await _client.GetAsync(
                "/api/v1/athletes/strava/callback?error=access_denied");

        Assert.Equal(
            HttpStatusCode.Redirect,
            response.StatusCode);

        Assert.Equal(
            "appkm://strava-callback/?status=denied",
            response.Headers.Location!.ToString());
    }

    [Fact]
    public async Task SignalRNegotiate_WithoutToken_ReturnsUnauthorized()
    {
        using var request =
            new HttpRequestMessage(
                HttpMethod.Post,
                "/hubs/redemptions/negotiate?negotiateVersion=1");

        HttpResponseMessage response =
            await _client.SendAsync(request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task Responses_IncludeSecurityAndCorrelationHeaders()
    {
        HttpResponseMessage response =
            await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        Assert.True(
            response.Headers.Contains("X-Correlation-ID"));

        Assert.Equal(
            "nosniff",
            response.Headers
                .GetValues("X-Content-Type-Options")
                .Single());

        Assert.Equal(
            "DENY",
            response.Headers
                .GetValues("X-Frame-Options")
                .Single());
    }
}
