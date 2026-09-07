using System.IdentityModel.Tokens.Jwt;
using AppKm.Identity.Api.Contracts;
using AppKm.Identity.Application.Commands.RegisterPushDevice;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppKm.Identity.Api.Controllers;

[ApiController]
[Route("api/v1/identity/push-devices")]
[Authorize]
public sealed class PushDevicesController : ControllerBase
{
    private readonly RegisterPushDeviceCommandHandler
        _registerPushDeviceHandler;

    public PushDevicesController(
        RegisterPushDeviceCommandHandler registerPushDeviceHandler)
    {
        _registerPushDeviceHandler = registerPushDeviceHandler;
    }

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Register(
        RegisterPushDeviceRequest request,
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(userIdValue, out Guid userId))
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(request.Token) ||
            string.IsNullOrWhiteSpace(request.Platform))
        {
            return BadRequest();
        }

        try
        {
            var command = new RegisterPushDeviceCommand(
                userId,
                request.Token,
                request.Platform);

            await _registerPushDeviceHandler.HandleAsync(
                command,
                cancellationToken);

            return NoContent();
        }
        catch (ArgumentException)
        {
            return BadRequest();
        }
    }
}
