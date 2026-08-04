namespace AppKm.Identity.Application.Commands.LoginUser;

public sealed record LoginUserCommand(
    string Email,
    string Password);