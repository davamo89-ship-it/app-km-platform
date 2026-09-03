using System.IdentityModel.Tokens.Jwt;
using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Application.Queries.GetPendingRedemptionConfirmations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/athletes/redemptions")]
[Authorize(Roles = "Athlete")]
public sealed class PendingRedemptionConfirmationsController : ControllerBase
{
    private readonly GetPendingRedemptionConfirmationsQueryHandler _handler;

    public PendingRedemptionConfirmationsController(
        IAthleteRepository athleteRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IMerchantRepository merchantRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _handler = new GetPendingRedemptionConfirmationsQueryHandler(
            athleteRepository,
            redemptionRequestRepository,
            merchantRepository,
            unitOfWork);
    }

    [HttpGet("pending-confirmations")]
    public async Task<IActionResult> GetPendingConfirmations(
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value
            ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (!Guid.TryParse(userIdValue, out Guid userId))
            return Unauthorized();

        var result = await _handler.HandleAsync(userId, cancellationToken);

        if (result.IsFailure)
            return BadRequest(new
            {
                code = result.Error.Code,
                message = result.Error.Message
            });

        return Ok(result.Value);
    }
}
