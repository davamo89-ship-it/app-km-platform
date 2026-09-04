using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Identity.Api.Contracts;
using AppKm.Identity.Api.Security;
using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Roles;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppKm.Identity.Api.Controllers;

[ApiController]
[Route("api/v1/admin/athletes")]
[Authorize(Policy = AuthorizationPolicies.AdminOnly)]
public sealed class AdminAthletesController : ControllerBase
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IUserRoleRepository _userRoleRepository;

    public AdminAthletesController(
        IAthleteRepository athleteRepository,
        IUserRoleRepository userRoleRepository)
    {
        _athleteRepository = athleteRepository;
        _userRoleRepository = userRoleRepository;
    }

    [HttpGet]
    [ProducesResponseType<IReadOnlyList<AdminAthleteResponse>>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<AdminAthleteResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        IReadOnlyList<Athlete> athleteProfiles =
            await _athleteRepository.GetAllAsync(
                cancellationToken);

        IReadOnlyCollection<Guid> athleteRoleUserIds =
            await _userRoleRepository.GetUserIdsByRoleNameAsync(
                RoleNames.Athlete,
                cancellationToken);

        IReadOnlyCollection<Guid> merchantRoleUserIds =
            await _userRoleRepository.GetUserIdsByRoleNameAsync(
                RoleNames.Merchant,
                cancellationToken);

        IReadOnlyCollection<Guid> adminRoleUserIds =
            await _userRoleRepository.GetUserIdsByRoleNameAsync(
                RoleNames.Admin,
                cancellationToken);

        HashSet<Guid> athleteUsers =
            athleteRoleUserIds.ToHashSet();

        HashSet<Guid> excludedUsers =
            merchantRoleUserIds
                .Concat(adminRoleUserIds)
                .ToHashSet();

        IReadOnlyList<AdminAthleteResponse> result =
            athleteProfiles
                .Where(athlete =>
                    athleteUsers.Contains(athlete.UserId) &&
                    !excludedUsers.Contains(athlete.UserId))
                .OrderBy(athlete => athlete.DisplayName)
                .ThenBy(athlete => athlete.CreatedAtUtc)
                .Select(athlete =>
                    new AdminAthleteResponse(
                        athlete.Id.Value,
                        athlete.UserId,
                        athlete.DisplayName,
                        athlete.ProfileImageUrl,
                        athlete.CountryCode,
                        athlete.BirthDate,
                        athlete.PreferredSport,
                        athlete.Status.ToString(),
                        athlete.CreatedAtUtc,
                        athlete.UpdatedAtUtc))
                .ToList();

        return Ok(result);
    }
}
