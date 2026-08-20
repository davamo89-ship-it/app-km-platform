using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Api.Contracts;
using AppKm.Athletes.Application.Queries.GetCurrentAthlete;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AppKm.Athletes.Application.Commands.UpdateAthleteProfile;
using AppKm.Athletes.Application.Queries.GetAthleteDashboard;
using AppKm.Athletes.Application.Queries.GetAthleteActivities;
using AppKm.Athletes.Application.Queries.GetAthleteSettings;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/athletes")]
public sealed class AthletesController : ControllerBase
{
    private readonly GetCurrentAthleteQueryHandler _handler;
    private readonly UpdateAthleteProfileCommandHandler _updateProfileHandler;
    private readonly GetAthleteDashboardQueryHandler
        _dashboardHandler;
    private readonly GetAthleteActivitiesQueryHandler
        _activitiesHandler;
    private readonly GetAthleteSettingsQueryHandler
        _settingsHandler;

    public AthletesController(
        GetCurrentAthleteQueryHandler handler,
        UpdateAthleteProfileCommandHandler updateProfileHandler,
        GetAthleteDashboardQueryHandler dashboardHandler,
        GetAthleteActivitiesQueryHandler activitiesHandler,
        GetAthleteSettingsQueryHandler settingsHandler)
    {
        _handler = handler;
        _updateProfileHandler = updateProfileHandler;
        _dashboardHandler = dashboardHandler;
        _activitiesHandler = activitiesHandler;
        _settingsHandler = settingsHandler;
    }

    [Authorize(Roles = "Athlete")]
[HttpPatch("me")]
[ProducesResponseType<UpdateAthleteProfileResponse>(
    StatusCodes.Status200OK)]
[ProducesResponseType(
    StatusCodes.Status400BadRequest)]
[ProducesResponseType(
    StatusCodes.Status401Unauthorized)]
[ProducesResponseType(
    StatusCodes.Status403Forbidden)]
[ProducesResponseType(
    StatusCodes.Status404NotFound)]
public async Task<IActionResult> UpdateMe(
    UpdateAthleteProfileRequest request,
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
        new UpdateAthleteProfileCommand(
            userId,
            request.DisplayName,
            request.ProfileImageUrl,
            request.CountryCode,
            request.BirthDate,
            request.PreferredSport);

    var result =
        await _updateProfileHandler.HandleAsync(
            command,
            cancellationToken);

    if (result.IsFailure)
    {
        if (result.Error.Code ==
            UpdateAthleteProfileErrors.NotFound.Code)
        {
            return NotFound();
        }

        return BadRequest(
            new
            {
                code = result.Error.Code,
                message = result.Error.Message
            });
    }

    return Ok(
        new UpdateAthleteProfileResponse(
            result.Value.AthleteId,
            result.Value.UserId,
            result.Value.DisplayName,
            result.Value.UpdatedAtUtc));

    }
    [Authorize(Roles = "Athlete")]
[HttpGet("dashboard")]
public async Task<IActionResult> GetDashboard(
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
        await _dashboardHandler.HandleAsync(
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

    [Authorize(Roles = "Athlete")]
    [HttpGet("activities")]
    public async Task<IActionResult> GetActivities(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
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

        var result =
            await _activitiesHandler.HandleAsync(
                userId,
                page,
                pageSize,
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
    [HttpGet("settings")]
    public async Task<IActionResult> GetSettings(
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
            await _settingsHandler.HandleAsync(
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
    [Authorize(Roles = "Athlete")]
    [HttpGet("me")]
    public async Task<IActionResult> GetMe(
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
            await _handler.HandleAsync(
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

        return Ok(
            new CurrentAthleteResponse(
                result.Value.AthleteId,
                result.Value.UserId,
                result.Value.DisplayName,
                result.Value.ProfileImageUrl,
                result.Value.CountryCode,
                result.Value.BirthDate,
                result.Value.PreferredSport,
                result.Value.Status.ToString(),
                result.Value.CreatedAtUtc,
                result.Value.UpdatedAtUtc));
    }

}