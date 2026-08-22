using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Api.Contracts;
using AppKm.Athletes.Application.Commands.CreateRedemptionRequest;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AppKm.Athletes.Application.Commands.CompleteRedemption;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/athletes/redemptions")]
[Authorize(Roles = "Athlete")]
public sealed class RedemptionsController : ControllerBase
{
    private readonly CreateRedemptionRequestCommandHandler
        _createHandler;
        
    private readonly CompleteRedemptionCommandHandler
        _completeHandler;

    public RedemptionsController(
        CreateRedemptionRequestCommandHandler createHandler,
        CompleteRedemptionCommandHandler completeHandler)
    {
        _createHandler = createHandler;
        _completeHandler = completeHandler;
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        CreateRedemptionRequestRequest request,
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
            new CreateRedemptionRequestCommand(
                userId,
                request.RequestedPoints);

        var result =
            await _createHandler.HandleAsync(
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

        return Ok(result.Value);
    }

    [HttpPost("complete")]
    public async Task<IActionResult> Complete(
        CompleteRedemptionRequest request,
        CancellationToken cancellationToken)
    {
        var command =
            new CompleteRedemptionCommand(
                request.Code);

        var result =
            await _completeHandler.HandleAsync(
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

        return Ok(result.Value);
    }
}