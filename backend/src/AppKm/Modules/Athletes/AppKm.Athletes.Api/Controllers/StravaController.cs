using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Api.Contracts;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AppKm.Athletes.Application.Commands.ConnectStrava;
using AppKm.Athletes.Application.Queries.GetStravaConnectionStatus;
using AppKm.Athletes.Application.Commands.DisconnectStrava;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/athletes/strava")]
public sealed class StravaController : ControllerBase
{
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

    public StravaController(
    IStravaAuthorizationService authorizationService,
    IOAuthStateGenerator stateGenerator,
    IOAuthStateStore stateStore,
    ConnectStravaCommandHandler connectStravaHandler,
    GetStravaConnectionStatusQueryHandler connectionStatusHandler,
    DisconnectStravaCommandHandler disconnectHandler)
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
            return BadRequest(new
            {
                error,
                message =
                    "Strava authorization was denied."
            });
        }

        if (string.IsNullOrWhiteSpace(code) ||
            string.IsNullOrWhiteSpace(state))
        {
            return BadRequest(new
            {
                message =
                    "Invalid Strava OAuth callback."
            });
        }

        bool validState =
            _stateStore.TryConsume(
                state,
                out Guid userId);

        if (!validState)
        {
            return BadRequest(new
            {
                code = "Strava.InvalidOAuthState",
                message =
                    "The OAuth state is invalid or has already been used."
            });
        }

        var command =
            new ConnectStravaCommand(
                userId,
                code);

        var result =
            await _connectStravaHandler.HandleAsync(
                command,
                cancellationToken);

        return Ok(new
        {
            message =
                "Strava account connected successfully.",
            stravaAthleteId =
                result.Value.StravaAthleteId,
            connectedAtUtc =
                result.Value.ConnectedAtUtc,
            scope
        });
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
    
}