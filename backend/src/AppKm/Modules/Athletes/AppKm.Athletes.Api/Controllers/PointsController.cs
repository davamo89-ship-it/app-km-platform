using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Application.Queries.GetPointBalance;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AppKm.Athletes.Application.Queries.GetPointHistory;
using AppKm.Athletes.Application.Queries.GetUpcomingPointExpirations;
using AppKm.Athletes.Application.Points;
using AppKm.Athletes.Application.Commands.ExpirePoints;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/athletes/points")]
[Authorize(Roles = "Athlete")]
public sealed class PointsController : ControllerBase
{
    private readonly GetPointBalanceQueryHandler
        _balanceHandler;
    private readonly GetPointHistoryQueryHandler
    _historyHandler;
    private readonly GetUpcomingPointExpirationsQueryHandler
    _expirationsHandler;
    private readonly PointExpirationService
    _expirationService;
    private readonly ExpireCurrentAthletePointsCommandHandler
    _expirePointsHandler;

    public PointsController(
        GetPointBalanceQueryHandler balanceHandler,
        GetPointHistoryQueryHandler historyHandler,
        GetUpcomingPointExpirationsQueryHandler expirationsHandler,
        PointExpirationService expirationService,
        ExpireCurrentAthletePointsCommandHandler expirePointsHandler)
    {
        _balanceHandler = balanceHandler;
        _historyHandler = historyHandler;
        _expirationsHandler = expirationsHandler;
        _expirationService = expirationService;
        _expirePointsHandler = expirePointsHandler;
    }

    [HttpGet("balance")]
    public async Task<IActionResult> GetBalance(
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
            await _balanceHandler.HandleAsync(
                userId,
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
            balance = result.Value.Balance
        });
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory(
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
            await _historyHandler.HandleAsync(
                userId,
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

        [HttpGet("expirations")]
    public async Task<IActionResult> GetUpcomingExpirations(
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
            await _expirationsHandler.HandleAsync(
                userId,
                DateTimeOffset.UtcNow,
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

    [HttpPost("expire")]
    public async Task<IActionResult> Expire(
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
            await _expirePointsHandler.HandleAsync(
                userId,
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
            expiredLots =
                result.Value.ExpiredLots,

            expiredPoints =
                result.Value.ExpiredPoints
        });
    }
}