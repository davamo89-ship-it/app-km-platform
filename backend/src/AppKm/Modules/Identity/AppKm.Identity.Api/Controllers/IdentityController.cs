using Microsoft.AspNetCore.Mvc;
using AppKm.Identity.Api.Contracts;
using AppKm.Identity.Application.Commands.RegisterUser;
using AppKm.Identity.Application.Commands.LoginUser;
using Platform.SharedKernel.Errors;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using AppKm.Identity.Application.Commands.RefreshSession;
using AppKm.Identity.Application.Commands.LogoutSession;
using AppKm.Identity.Application.Commands.RequestPasswordReset;
using AppKm.Identity.Application.Commands.ConfirmPasswordReset;

namespace AppKm.Identity.Api.Controllers;

[ApiController]
[Route("api/v1/identity")]
public sealed class IdentityController : ControllerBase
{
    private readonly RegisterUserCommandHandler _registerUserHandler;
    private readonly LoginUserCommandHandler _loginUserHandler;
    private readonly RefreshSessionCommandHandler _refreshSessionHandler;
    private readonly LogoutSessionCommandHandler _logoutSessionHandler;
    private readonly RequestPasswordResetCommandHandler _requestPasswordResetHandler;
    private readonly ConfirmPasswordResetCommandHandler _confirmPasswordResetHandler;
    private readonly ILogger<IdentityController> _logger;

    public IdentityController(
        RegisterUserCommandHandler registerUserHandler,
        LoginUserCommandHandler loginUserHandler,
        RefreshSessionCommandHandler refreshSessionHandler,
        LogoutSessionCommandHandler logoutSessionHandler,
        RequestPasswordResetCommandHandler requestPasswordResetHandler,
        ConfirmPasswordResetCommandHandler confirmPasswordResetHandler,
        ILogger<IdentityController> logger)
    {
        _registerUserHandler = registerUserHandler;
        _loginUserHandler = loginUserHandler;
        _refreshSessionHandler = refreshSessionHandler;
        _logoutSessionHandler = logoutSessionHandler;
        _requestPasswordResetHandler = requestPasswordResetHandler;
        _confirmPasswordResetHandler = confirmPasswordResetHandler;
        _logger = logger;
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
    [EnableRateLimiting("identity-auth")]
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
    [HttpPost("login")]
    [EnableRateLimiting("identity-auth")]
    [ProducesResponseType<LoginUserResponse>(
        StatusCodes.Status200OK)]
    [ProducesResponseType<ErrorResponse>(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType<ErrorResponse>(
        StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Login(
        LoginUserRequest request,
        CancellationToken cancellationToken)
    {
        var command = new LoginUserCommand(
            request.Email,
            request.Password);

        var result = await _loginUserHandler.HandleAsync(
            command,
            cancellationToken);

        if (result.IsFailure)
        {
            var errorResponse = ToErrorResponse(result.Error);

            if (result.Error.Code ==
                LoginUserErrors.AccountNotActive.Code)
            {
                return StatusCode(
                    StatusCodes.Status403Forbidden,
                    errorResponse);
            }

            return Unauthorized(errorResponse);
        }

            var response = new LoginUserResponse(
            result.Value.UserId.Value,
            result.Value.Email,
            result.Value.AccessToken,
            result.Value.AccessTokenExpiresAtUtc,
            result.Value.RefreshToken,
            result.Value.RefreshTokenExpiresAtUtc);

        return Ok(response);
    }


    [HttpPost("password-reset/request")]
    [EnableRateLimiting("identity-password-reset")]
    [ProducesResponseType<PasswordResetRequestResponse>(
        StatusCodes.Status202Accepted)]
    public async Task<IActionResult> RequestPasswordReset(
        RequestPasswordResetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            await _requestPasswordResetHandler.HandleAsync(
                new RequestPasswordResetCommand(
                    request.Email),
                cancellationToken);
        }
        catch (Exception exception)
        {
            // No se devuelve un error específico para no revelar
            // si el correo corresponde a una cuenta existente.
            _logger.LogError(
                exception,
                "Password reset delivery failed.");
        }

        return Accepted(
            new PasswordResetRequestResponse(
                "Si existe una cuenta con ese correo, recibirás un código para recuperar tu contraseña."));
    }

    [HttpPost("password-reset/confirm")]
    [EnableRateLimiting("identity-password-reset")]
    [ProducesResponseType(
        StatusCodes.Status204NoContent)]
    [ProducesResponseType<ErrorResponse>(
        StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ConfirmPasswordReset(
        ConfirmPasswordResetRequest request,
        CancellationToken cancellationToken)
    {
        var result =
            await _confirmPasswordResetHandler.HandleAsync(
                new ConfirmPasswordResetCommand(
                    request.Email,
                    request.Code,
                    request.NewPassword),
                cancellationToken);

        if (result.IsFailure)
        {
            return BadRequest(
                ToErrorResponse(result.Error));
        }

        return NoContent();
    }

    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType<CurrentUserResponse>(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    public ActionResult<CurrentUserResponse> GetCurrentUser()
    {
        string? userIdValue =
            User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        string? email =
            User.FindFirst(JwtRegisteredClaimNames.Email)?.Value;

        if (!Guid.TryParse(userIdValue, out Guid userId) ||
            string.IsNullOrWhiteSpace(email))
        {
            return Unauthorized();
        }
        string[] roles = User
            .FindAll("role")
            .Select(claim => claim.Value)
            .Distinct(StringComparer.Ordinal)
            .OrderBy(role => role)
            .ToArray();

        return Ok(
            new CurrentUserResponse(
                userId,
                email,
                roles));
    }

        [HttpPost("refresh")]
        [EnableRateLimiting("identity-refresh")]
        [ProducesResponseType<RefreshSessionResponse>(
            StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorResponse>(
            StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Refresh(
            RefreshSessionRequest request,
            CancellationToken cancellationToken)
        {
            var command = new RefreshSessionCommand(
                request.RefreshToken);

            var result = await _refreshSessionHandler.HandleAsync(
                command,
                cancellationToken);

            if (result.IsFailure)
            {
                return Unauthorized(
                    ToErrorResponse(result.Error));
            }

            var response = new RefreshSessionResponse(
                result.Value.UserId,
                result.Value.Email,
                result.Value.AccessToken,
                result.Value.AccessTokenExpiresAtUtc,
                result.Value.RefreshToken,
                result.Value.RefreshTokenExpiresAtUtc);

            return Ok(response);
        }

        [HttpPost("logout")]
        [ProducesResponseType(
            StatusCodes.Status204NoContent)]
        [ProducesResponseType<ErrorResponse>(
            StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Logout(
            LogoutSessionRequest request,
            CancellationToken cancellationToken)
        {
            var command = new LogoutSessionCommand(
                request.RefreshToken);

            var result = await _logoutSessionHandler.HandleAsync(
                command,
                cancellationToken);

            if (result.IsFailure)
            {
                return BadRequest(
                    ToErrorResponse(result.Error));
            }

            return NoContent();
        }
}

public sealed record IdentityStatusResponse(
    string Module,
    string Status,
    string ApiVersion,
    DateTimeOffset TimestampUtc);
