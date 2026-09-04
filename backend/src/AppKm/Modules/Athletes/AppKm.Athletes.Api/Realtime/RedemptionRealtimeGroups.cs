namespace AppKm.Athletes.Api.Realtime;

public static class RedemptionRealtimeGroups
{
    public static string User(Guid userId)
    {
        return $"user:{userId:D}";
    }
}
