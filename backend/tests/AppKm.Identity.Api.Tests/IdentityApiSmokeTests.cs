using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace AppKm.Identity.Api.Tests;

public sealed class IdentityApiSmokeTests
    : IClassFixture<IdentityApiFactory>
{
    private readonly HttpClient _client;

    public IdentityApiSmokeTests(IdentityApiFactory factory)
    {
        _client =
            factory.CreateClient(
                new Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactoryClientOptions
                {
                    AllowAutoRedirect = false
                });
    }

    [Fact]
    public async Task Root_ReturnsServiceMetadata()
    {
        HttpResponseMessage response =
            await _client.GetAsync("/");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using JsonDocument body =
            JsonDocument.Parse(
                await response.Content.ReadAsStringAsync());

        Assert.Equal(
            "AppKm.Identity.Api",
            body.RootElement.GetProperty("service").GetString());

        Assert.Equal(
            "running",
            body.RootElement.GetProperty("status").GetString());

        Assert.Equal(
            "v1",
            body.RootElement.GetProperty("version").GetString());
    }

    [Fact]
    public async Task Status_ReturnsOperational()
    {
        HttpResponseMessage response =
            await _client.GetAsync("/api/v1/identity/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using JsonDocument body =
            JsonDocument.Parse(
                await response.Content.ReadAsStringAsync());

        Assert.Equal(
            "Identity",
            body.RootElement.GetProperty("module").GetString());

        Assert.Equal(
            "Operational",
            body.RootElement.GetProperty("status").GetString());

        Assert.Equal(
            "v1",
            body.RootElement.GetProperty("apiVersion").GetString());
    }

    [Fact]
    public async Task Health_ReturnsOkWithoutExternalDatabase()
    {
        HttpResponseMessage response =
            await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Me_WithoutBearerToken_ReturnsUnauthorized()
    {
        HttpResponseMessage response =
            await _client.GetAsync("/api/v1/identity/me");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Theory]
    [InlineData("/api/v1/identity/access/athlete")]
    [InlineData("/api/v1/identity/access/merchant")]
    [InlineData("/api/v1/identity/access/admin")]
    [InlineData("/api/v1/admin/athletes")]
    [InlineData("/api/v1/admin/merchants")]
    public async Task ProtectedRoutes_WithoutToken_ReturnUnauthorized(
        string path)
    {
        HttpResponseMessage response =
            await _client.GetAsync(path);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task Register_InvalidEmail_ReturnsBadRequest()
    {
        HttpResponseMessage response =
            await _client.PostAsJsonAsync(
                "/api/v1/identity/register",
                new
                {
                    email = "not-an-email",
                    password = "Password1"
                });

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task Login_InvalidEmail_ReturnsUnauthorized()
    {
        HttpResponseMessage response =
            await _client.PostAsJsonAsync(
                "/api/v1/identity/login",
                new
                {
                    email = "not-an-email",
                    password = "Password1"
                });

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task Refresh_EmptyToken_ReturnsUnauthorized()
    {
        HttpResponseMessage response =
            await _client.PostAsJsonAsync(
                "/api/v1/identity/refresh",
                new
                {
                    refreshToken = ""
                });

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task Logout_EmptyToken_ReturnsBadRequest()
    {
        HttpResponseMessage response =
            await _client.PostAsJsonAsync(
                "/api/v1/identity/logout",
                new
                {
                    refreshToken = ""
                });

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task Responses_IncludeSecurityAndCorrelationHeaders()
    {
        HttpResponseMessage response =
            await _client.GetAsync("/api/v1/identity/status");

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
