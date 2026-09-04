using AppKm.Athletes.Application.Queries.GetAdminAthletes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/admin/athletes")]
[Authorize(Roles = "Admin")]
public sealed class AdminAthletesController : ControllerBase
{
    private readonly GetAdminAthletesQueryHandler _handler;

    public AdminAthletesController(
        GetAdminAthletesQueryHandler handler)
    {
        _handler = handler;
    }

    [HttpGet]
    [ProducesResponseType<IReadOnlyList<GetAdminAthleteItem>>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<GetAdminAthleteItem>>> GetAll(
        CancellationToken cancellationToken)
    {
        IReadOnlyList<GetAdminAthleteItem> athletes =
            await _handler.HandleAsync(
                cancellationToken);

        return Ok(athletes);
    }
}
