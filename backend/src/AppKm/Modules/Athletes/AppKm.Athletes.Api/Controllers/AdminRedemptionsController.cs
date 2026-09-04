using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppKm.Athletes.Api.Controllers;

[ApiController]
[Route("api/v1/admin/redemptions")]
[Authorize(Roles = "Admin")]
public sealed class AdminRedemptionsController : ControllerBase
{
    private const int ResultLimit = 100;

    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly IMerchantRepository _merchantRepository;

    public AdminRedemptionsController(
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteRepository athleteRepository,
        IMerchantRepository merchantRepository)
    {
        _redemptionRequestRepository = redemptionRequestRepository;
        _athleteRepository = athleteRepository;
        _merchantRepository = merchantRepository;
    }

    [HttpGet]
    [ProducesResponseType<IReadOnlyList<AdminRedemptionResponse>>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<AdminRedemptionResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        IReadOnlyList<RedemptionRequest> requests =
            await _redemptionRequestRepository.GetAllAsync(
                ResultLimit,
                cancellationToken);

        var result = new List<AdminRedemptionResponse>(requests.Count);

        foreach (RedemptionRequest request in requests)
        {
            Athlete? athlete = await _athleteRepository.GetByIdAsync(
                AthleteId.From(request.AthleteId),
                cancellationToken);

            string? merchantName = null;

            if (request.MerchantId is Guid merchantId)
            {
                Merchant? merchant = await _merchantRepository.GetByIdAsync(
                    new MerchantId(merchantId),
                    cancellationToken);

                merchantName = merchant?.BusinessName;
            }

            result.Add(
                new AdminRedemptionResponse(
                    request.Id.Value,
                    request.Code,
                    request.AthleteId,
                    athlete?.DisplayName ?? "Atleta",
                    request.MerchantId,
                    merchantName,
                    request.RequestedPoints,
                    request.ProposedPoints,
                    request.Status.ToString(),
                    request.CreatedAtUtc,
                    request.ExpiresAtUtc,
                    request.MerchantProposedAtUtc,
                    request.AthleteConfirmedAtUtc,
                    request.CompletedAtUtc));
        }

        return Ok(result);
    }
}

public sealed record AdminRedemptionResponse(
    Guid RedemptionRequestId,
    string Code,
    Guid AthleteId,
    string AthleteDisplayName,
    Guid? MerchantId,
    string? MerchantName,
    int RequestedPoints,
    int? ProposedPoints,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset ExpiresAtUtc,
    DateTimeOffset? MerchantProposedAtUtc,
    DateTimeOffset? AthleteConfirmedAtUtc,
    DateTimeOffset? CompletedAtUtc);
