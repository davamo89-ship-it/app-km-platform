using Microsoft.AspNetCore.Mvc;
using AppKm.Identity.Api.Contracts;
using AppKm.Identity.Application.Commands.RegisterUser;
using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Api.Controllers;

[ApiController]
[Route("api/v1/identity")]
public sealed class IdentityController : ControllerBase
{
    private readonly RegisterUserCommandHandler _registerUserHandler;

    public IdentityController(
        RegisterUserCommandHandler registerUserHandler)
    {
        _registerUserHandler = registerUserHandler;
    }
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
    [HttpPost("register")]
    [ProducesResponseType<RegisterUserResponse>(
        StatusCodes.Status201Created)]
    [ProducesResponseType<ErrorResponse>(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ErrorResponse>(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Register(
        RegisterUserRequest request,
        CancellationToken cancellationToken)
    {
        var command = new RegisterUserCommand(
            request.Email,
            request.Password);

        var result = await _registerUserHandler.HandleAsync(
            command,
            cancellationToken);

        if (result.IsFailure)
        {
            return result.Error.Code ==
                RegisterUserErrors.EmailAlreadyExists.Code
                ? Conflict(ToErrorResponse(result.Error))
                : BadRequest(ToErrorResponse(result.Error));
        }

        var response = new RegisterUserResponse(
            result.Value.Value,
            request.Email.Trim().ToLowerInvariant());

        return Created(
            $"/api/v1/identity/users/{result.Value.Value}",
            response);
    }
    private static ErrorResponse ToErrorResponse(Error error)
    {
        return new ErrorResponse(
            error.Code,
            error.Message);
    }
}

public sealed record IdentityStatusResponse(
    string Module,
    string Status,
    string ApiVersion,
    DateTimeOffset TimestampUtc);