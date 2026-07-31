using Microsoft.AspNetCore.Mvc;

namespace AppKm.Identity.Api.Controllers;

[ApiController]
[Route("api/v1/identity")]
public sealed class IdentityController : ControllerBase
{
    [HttpGet("status")]
    [ProducesResponseType<IdentityStatusResponse>(
        StatusCodes.Status200OK)]
    public ActionResult<IdentityStatusResponse> GetStatus()
    {
        var response = new IdentityStatusResponse(
            Module: "Identity",
            Status: "Operational",
            ApiVersion: "v1",
            TimestampUtc: DateTimeOffset.UtcNow);

        return Ok(response);
    }
}

public sealed record IdentityStatusResponse(
    string Module,
    string Status,
    string ApiVersion,
    DateTimeOffset TimestampUtc);