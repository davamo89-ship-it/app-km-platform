using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Abstractions;

namespace AppKm.Identity.Application.Commands.RequestPasswordReset;

public sealed class RequestPasswordResetCommandHandler
{
    private static readonly TimeSpan CodeLifetime =
        TimeSpan.FromMinutes(15);

    private readonly IUserRepository _userRepository;
    private readonly IPasswordResetCodeGenerator _codeGenerator;
    private readonly IPasswordResetEmailSender _emailSender;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

    public RequestPasswordResetCommandHandler(
        IUserRepository userRepository,
        IPasswordResetCodeGenerator codeGenerator,
        IPasswordResetEmailSender emailSender,
        IUnitOfWork unitOfWork,
        IClock clock)
    {
        _userRepository = userRepository;
        _codeGenerator = codeGenerator;
        _emailSender = emailSender;
        _unitOfWork = unitOfWork;
        _clock = clock;
    }

    public async Task HandleAsync(
        RequestPasswordResetCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        var emailResult =
            Email.Create(command.Email);

        // La solicitud es deliberadamente silenciosa para evitar
        // revelar si una cuenta existe o no.
        if (emailResult.IsFailure)
        {
            return;
        }

        User? user =
            await _userRepository.GetByEmailAsync(
                emailResult.Value,
                cancellationToken);

        if (user is null ||
            user.Status != UserStatus.Active)
        {
            return;
        }

        PasswordResetCode code =
            _codeGenerator.Generate();

        DateTimeOffset utcNow =
            _clock.UtcNow;

        DateTimeOffset expiresAtUtc =
            utcNow.Add(CodeLifetime);

        user.BeginPasswordReset(
            code.CodeHash,
            utcNow,
            expiresAtUtc);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        await _emailSender.SendCodeAsync(
            user.Email.Value,
            code.Code,
            expiresAtUtc,
            cancellationToken);
    }
}
