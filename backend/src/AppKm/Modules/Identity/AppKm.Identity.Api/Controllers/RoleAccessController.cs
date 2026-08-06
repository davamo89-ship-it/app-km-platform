using AppKm.Identity.Api.Contracts;
using AppKm.Identity.Api.Security;
using AppKm.Identity.Domain.Aggregates.Roles;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppKm.Identity.Api.Controllers;

[ApiController]
[Route("api/v1/identity/access")]
public sealed class RoleAccessController : ControllerBase
{
    [Authorize(
        Policy = AuthorizationPolicies.AthleteOnly)]
    [HttpGet("athlete")]
    [ProducesResponseType<RoleAccessResponse>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status403Forbidden)]
    public ActionResult<RoleAccessResponse> Athlete()
    {
        return Ok(
            new RoleAccessResponse(
                "Access granted to the athlete resource.",
                RoleNames.Athlete));
    }

    [Authorize(
        Policy = AuthorizationPolicies.MerchantOnly)]
    [HttpGet("merchant")]
    [ProducesResponseType<RoleAccessResponse>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status403Forbidden)]
    public ActionResult<RoleAccessResponse> Merchant()
    {
        return Ok(
            new RoleAccessResponse(
                "Access granted to the merchant resource.",
                RoleNames.Merchant));
    }

    [Authorize(
        Policy = AuthorizationPolicies.AdminOnly)]
    [HttpGet("admin")]
    [ProducesResponseType<RoleAccessResponse>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status403Forbidden)]
    public ActionResult<RoleAccessResponse> Admin()
    {
        return Ok(
            new RoleAccessResponse(
                "Access granted to the administrator resource.",
                RoleNames.Admin));
    }
}