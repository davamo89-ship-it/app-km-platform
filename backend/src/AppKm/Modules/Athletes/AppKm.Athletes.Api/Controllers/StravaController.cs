using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Api.Contracts;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AppKm.Athletes.Application.Commands.ConnectStrava;
using AppKm.Athletes.Application.Queries.GetStravaConnectionStatus;
using AppKm.Athletes.Application.Commands.DisconnectStrava;
using AppKm.Athletes.Application.Queries.GetStravaActivities;
using AppKm.Athletes.Application.Commands.SyncStravaActivities;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/athletes/strava")]
public sealed class StravaController : ControllerBase
{
    private const string AppCallbackBaseUrl =
        "appkm://strava-callback";

    private readonly IStravaAuthorizationService
        _authorizationService;

    private readonly IOAuthStateGenerator
        _stateGenerator;

    private readonly IOAuthStateStore
        _stateStore;

    private readonly ConnectStravaCommandHandler
        _connectStravaHandler;

    private readonly GetStravaConnectionStatusQueryHandler
        _connectionStatusHandler;

    private readonly DisconnectStravaCommandHandler
        _disconnectHandler;

    private readonly GetStravaActivitiesQueryHandler
        _activitiesHandler;

    private readonly SyncStravaActivitiesCommandHandler
        _syncActivitiesHandler;

    public StravaController(
        IStravaAuthorizationService authorizationService,
        IOAuthStateGenerator stateGenerator,
        IOAuthStateStore stateStore,
        ConnectStravaCommandHandler connectStravaHandler,
        GetStravaConnectionStatusQueryHandler connectionStatusHandler,
        DisconnectStravaCommandHandler disconnectHandler,
        GetStravaActivitiesQueryHandler activitiesHandler,
        SyncStravaActivitiesCommandHandler syncActivitiesHandler)
    {
        _authorizationService =
            authorizationService;

        _stateGenerator =
            stateGenerator;

        _stateStore =
            stateStore;

        _connectStravaHandler =
            connectStravaHandler;

        _connectionStatusHandler =
            connectionStatusHandler;

        _disconnectHandler =
            disconnectHandler;

        _activitiesHandler =
            activitiesHandler;

        _syncActivitiesHandler =
            syncActivitiesHandler;
    }

    [HttpGet("callback")]
    [AllowAnonymous]
    public async Task<IActionResult> Callback(
        [FromQuery] string? code,
        [FromQuery] string? state,
        [FromQuery] string? error,
        [FromQuery] string? scope,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(error))
        {
            return RedirectToApp(
                "denied");
        }

        if (string.IsNullOrWhiteSpace(code) ||
            string.IsNullOrWhiteSpace(state))
        {
            return RedirectToApp(
                "invalid_callback");
        }

        bool validState =
            _stateStore.TryConsume(
                state,
                out Guid userId);

        if (!validState)
        {
            return RedirectToApp(
                "invalid_state");
        }

        var command =
            new ConnectStravaCommand(
                userId,
                code);

        var result =
            await _connectStravaHandler.HandleAsync(
                command,
                cancellationToken);

        if (result.IsFailure)
        {
            return RedirectToApp(
                "connection_failed");
        }

        return RedirectToApp(
            "connected");
    }

    [Authorize(Roles = "Athlete")]
    [HttpGet("connect")]
    [ProducesResponseType<StravaConnectResponse>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status403Forbidden)]
    public ActionResult<StravaConnectResponse> Connect()
    {
        string? userIdValue =
            User.FindFirst(
                JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized();
        }

        string state =
            _stateGenerator.Generate();

        _stateStore.Store(
            state,
            userId);

        string authorizationUrl =
            _authorizationService
                .BuildAuthorizationUrl(state);

        return Ok(
            new StravaConnectResponse(
                authorizationUrl));
    }

    [Authorize(Roles = "Athlete")]
    [HttpGet("status")]
    [ProducesResponseType<StravaConnectionStatusResponse>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<StravaConnectionStatusResponse>>
        GetStatus(
            CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirst(
                JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized();
        }

        var result =
            await _connectionStatusHandler.HandleAsync(
                userId,
                cancellationToken);

        return Ok(
            new StravaConnectionStatusResponse(
                result.Connected,
                result.StravaAthleteId,
                result.Status,
                result.ConnectedAtUtc,
                result.AccessTokenExpiresAtUtc));
    }

    [Authorize(Roles = "Athlete")]
    [HttpGet("activities")]
    public async Task<IActionResult> GetActivities(
        [FromQuery] DateTimeOffset? after,
        [FromQuery] DateTimeOffset? before,
        [FromQuery] int page = 1,
        [FromQuery] int perPage = 30,
        CancellationToken cancellationToken = default)
    {
        string? userIdValue =
            User.FindFirst(
                JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized();
        }

        var query =
            new GetStravaActivitiesQuery(
                userId,
                after,
                before,
                page,
                perPage);

        var result =
            await _activitiesHandler.HandleAsync(
                query,
                cancellationToken);

        if (result.IsFailure)
        {
            return BadRequest(new
            {
                code = result.Error.Code,
                message = result.Error.Message
            });
        }

        return Ok(result.Value);
    }

    [Authorize(Roles = "Athlete")]
    [HttpPost("sync")]
    public async Task<IActionResult> SyncActivities(
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirst(
                JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized();
        }

        var command =
            new SyncStravaActivitiesCommand(
                userId);

        var result =
            await _syncActivitiesHandler.HandleAsync(
                command,
                cancellationToken);

        if (result.IsFailure)
        {
            return BadRequest(new
            {
                code = result.Error.Code,
                message = result.Error.Message
            });
        }

        return Ok(new
        {
            retrieved =
                result.Value.Retrieved,

            saved =
                result.Value.Saved,

            skippedInvalid =
                result.Value.SkippedInvalid,

            skippedDuplicate =
                result.Value.SkippedDuplicate
        });
    }

    [Authorize(Roles = "Athlete")]
    [HttpDelete("disconnect")]
    public async Task<IActionResult> Disconnect(
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirst(
                JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized();
        }

        var command =
            new DisconnectStravaCommand(
                userId);

        var result =
            await _disconnectHandler.HandleAsync(
                command,
                cancellationToken);

        if (result.IsFailure)
        {
            return BadRequest(new
            {
                code = result.Error.Code,
                message = result.Error.Message
            });
        }

        return Ok(new
        {
            disconnected = true,
            athleteId = result.Value.AthleteId,
            status = result.Value.Status,
            disconnectedAtUtc =
                result.Value.DisconnectedAtUtc
        });
    }

    private RedirectResult RedirectToApp(
        string status)
    {
        string url =
            $"{AppCallbackBaseUrl}?status={Uri.EscapeDataString(status)}";

        return Redirect(url);
    }
}
