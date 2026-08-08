using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Api.Contracts;
using AppKm.Athletes.Application.Queries.GetCurrentAthlete;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AppKm.Athletes.Application.Commands.UpdateAthleteProfile;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/athletes")]
public sealed class AthletesController : ControllerBase
{
    private readonly GetCurrentAthleteQueryHandler _handler;
    private readonly UpdateAthleteProfileCommandHandler _updateProfileHandler;

    public AthletesController(
        GetCurrentAthleteQueryHandler handler,
        UpdateAthleteProfileCommandHandler updateProfileHandler)
    {
        _handler = handler;
        _updateProfileHandler = updateProfileHandler;
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
            request.DisplayName);

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
}