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
[Route("api/v1/admin/merchants")]
[Authorize(Policy = AuthorizationPolicies.AdminOnly)]
public sealed class AdminMerchantsController : ControllerBase
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IUserRoleRepository _userRoleRepository;

    public AdminMerchantsController(
        IAthleteRepository athleteRepository,
        IUserRoleRepository userRoleRepository)
    {
        _athleteRepository = athleteRepository;
        _userRoleRepository = userRoleRepository;
    }

    [HttpGet]
    [ProducesResponseType<IReadOnlyList<AdminMerchantResponse>>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<AdminMerchantResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        IReadOnlyList<Athlete> profiles =
            await _athleteRepository.GetAllAsync(cancellationToken);

        IReadOnlyCollection<Guid> merchantRoleUserIds =
            await _userRoleRepository.GetUserIdsByRoleNameAsync(
                RoleNames.Merchant,
                cancellationToken);

        HashSet<Guid> merchantUsers = merchantRoleUserIds.ToHashSet();

        IReadOnlyList<AdminMerchantResponse> result =
            profiles
                .Where(profile => merchantUsers.Contains(profile.UserId))
                .OrderBy(profile => profile.DisplayName)
                .ThenBy(profile => profile.CreatedAtUtc)
                .Select(profile =>
                    new AdminMerchantResponse(
                        profile.Id.Value,
                        profile.UserId,
                        profile.DisplayName,
                        profile.ProfileImageUrl,
                        profile.CountryCode,
                        profile.PreferredSport,
                        profile.Status.ToString(),
                        profile.CreatedAtUtc,
                        profile.UpdatedAtUtc))
                .ToList();

        return Ok(result);
    }
}
