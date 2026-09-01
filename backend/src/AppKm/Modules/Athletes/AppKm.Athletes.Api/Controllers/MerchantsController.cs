using System.Security.Claims;
using AppKm.Athletes.Api.Contracts;
using AppKm.Athletes.Application.Commands.ProposeMerchantRedemption;
using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Application.Queries.GetLatestMerchantRedemption;
using AppKm.Athletes.Application.Queries.GetMerchantProfile;
using AppKm.Athletes.Application.Queries.ValidateMerchantRedemption;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/merchants")]
[Authorize(Roles = "Merchant")]
public sealed class MerchantsController : ControllerBase
{
    private readonly GetMerchantProfileQueryHandler
        _getMerchantProfileHandler;
    private readonly ValidateMerchantRedemptionQueryHandler
        _validateRedemptionHandler;
    private readonly ProposeMerchantRedemptionCommandHandler
        _proposeRedemptionHandler;
    private readonly GetLatestMerchantRedemptionQueryHandler
        _getLatestRedemptionHandler;

    public MerchantsController(
        GetMerchantProfileQueryHandler getMerchantProfileHandler,
        ValidateMerchantRedemptionQueryHandler validateRedemptionHandler,
        ProposeMerchantRedemptionCommandHandler proposeRedemptionHandler,
        IMerchantRepository merchantRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteRepository athleteRepository)
    {
        _getMerchantProfileHandler =
            getMerchantProfileHandler;
        _validateRedemptionHandler =
            validateRedemptionHandler;
        _proposeRedemptionHandler =
            proposeRedemptionHandler;

        // Se construye aquí para no requerir un cambio adicional
        // en el registro de DI de este Sprint.
        _getLatestRedemptionHandler =
            new GetLatestMerchantRedemptionQueryHandler(
                merchantRepository,
                redemptionRequestRepository,
                athleteRepository);
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMe(
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized(new
            {
                code = "Authentication.InvalidUser",
                message =
                    "The authenticated user identifier is invalid."
            });
        }

        var result =
            await _getMerchantProfileHandler.HandleAsync(
                new GetMerchantProfileQuery(userId),
                cancellationToken);

        if (result.IsFailure)
        {
            return NotFound(new
            {
                code = result.Error.Code,
                message = result.Error.Message
            });
        }

        return Ok(result.Value);
    }

    [HttpGet("redemptions/latest")]
    public async Task<IActionResult> GetLatestRedemption(
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized(new
            {
                code = "Authentication.InvalidUser",
                message =
                    "The authenticated user identifier is invalid."
            });
        }

        var result =
            await _getLatestRedemptionHandler.HandleAsync(
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

        if (result.Value is null)
        {
            return NoContent();
        }

        return Ok(result.Value);
    }

    [HttpGet("redemptions/{code}")]
    public async Task<IActionResult> ValidateRedemption(
        string code,
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized(new
            {
                code = "Authentication.InvalidUser",
                message =
                    "The authenticated user identifier is invalid."
            });
        }

        var result =
            await _validateRedemptionHandler.HandleAsync(
                userId,
                code,
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

    [HttpPost("redemptions/{code}/proposal")]
    public async Task<IActionResult> ProposeRedemption(
        string code,
        ProposeMerchantRedemptionRequest request,
        CancellationToken cancellationToken)
    {
        string? userIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(
                userIdValue,
                out Guid userId))
        {
            return Unauthorized(new
            {
                code = "Authentication.InvalidUser",
                message =
                    "The authenticated user identifier is invalid."
            });
        }

        var command =
            new ProposeMerchantRedemptionCommand(
                userId,
                code,
                request.ProposedPoints);

        var result =
            await _proposeRedemptionHandler.HandleAsync(
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
