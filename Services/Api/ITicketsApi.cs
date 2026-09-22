using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface ITicketsApi
{
    [Get("/api/events/{eventId}/my/tickets")]
    Task<MyTicketsResponseDto> GetMyTicketsByEventAsync(string eventId);

    [Get("/api/users/me/tickets")]
    Task<PaginateMyTicketsDto> GetMyTicketsAsync(int page = 1, int limit = 100, string? eventId = null);
}
