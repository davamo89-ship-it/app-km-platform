using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace AppKm.Athletes.Api.Realtime;

[Authorize]
public sealed class RedemptionHub : Hub
{
    public const string Path = "/hubs/redemptions";

    public override async Task OnConnectedAsync()
    {
        string? userId =
            Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        if (Guid.TryParse(userId, out Guid parsedUserId))
        {
            await Groups.AddToGroupAsync(
                Context.ConnectionId,
                RedemptionRealtimeGroups.User(parsedUserId));
        }

        await base.OnConnectedAsync();
    }
}
