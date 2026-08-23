using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Api.Contracts;
using AppKm.Athletes.Application.Commands.CreateRedemptionRequest;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AppKm.Athletes.Application.Commands.CompleteRedemption;
using AppKm.Athletes.Application.Commands.CancelRedemption;
using AppKm.Athletes.Application.Queries.GetRedemptionRequests;
using AppKm.Athletes.Application.Commands.ConfirmAthleteRedemption;

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
    
    private readonly CancelRedemptionCommandHandler
        _cancelHandler;
        
    private readonly GetRedemptionRequestsQueryHandler
        _getRequestsHandler;
    
    private readonly ConfirmAthleteRedemptionCommandHandler
        _confirmAthleteRedemptionHandler;

    public RedemptionsController(
        CreateRedemptionRequestCommandHandler createHandler,
        CompleteRedemptionCommandHandler completeHandler,
        CancelRedemptionCommandHandler cancelHandler,
        GetRedemptionRequestsQueryHandler getRequestsHandler,
        ConfirmAthleteRedemptionCommandHandler confirmAthleteRedemptionHandler)
    {
        _createHandler = createHandler;
        _completeHandler = completeHandler;
        _cancelHandler = cancelHandler;
        _getRequestsHandler = getRequestsHandler;
        _confirmAthleteRedemptionHandler = confirmAthleteRedemptionHandler;
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

    [HttpPost("cancel")]
    public async Task<IActionResult> Cancel(
        CancelRedemptionRequest request,
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
            new CancelRedemptionCommand(
                userId,
                request.Code);

        var result =
            await _cancelHandler.HandleAsync(
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

            [HttpGet]
        public async Task<IActionResult> GetAll(
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
                await _getRequestsHandler.HandleAsync(
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
        [HttpPost("{code}/confirm")]
        public async Task<IActionResult> ConfirmByAthlete(
            string code,
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
                new ConfirmAthleteRedemptionCommand(
                    userId,
                    code);

            var result =
                await _confirmAthleteRedemptionHandler.HandleAsync(
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