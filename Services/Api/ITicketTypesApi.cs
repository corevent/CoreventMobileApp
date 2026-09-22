using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface ITicketTypesApi
{
    [Get("/api/events/{eventId}/ticket-types")]
    Task<TicketTypeListPageDto> GetAllAsync(
        string eventId,
        int page = 1, int limit = 10,
        bool availableOnly = false,
        string? name = null,
        [Query(Format = "yyyy-MM-ddTHH:mm:ss.fffZ")] DateTime? startDate = null,
        [Query(Format = "yyyy-MM-ddTHH:mm:ss.fffZ")] DateTime? endDate = null);

    [Post("/api/events/{eventId}/ticket-types")]
    Task<TicketTypeResponseDto> CreateAsync(string eventId, [Body] CreateTicketTypeDto dto);

    [Patch("/api/events/ticket-types/{ticketTypeId}")]
    Task<TicketTypeResponseDto> UpdateAsync(string ticketTypeId, [Body] UpdateTicketTypeDto dto);

    [Delete("/api/events/ticket-types/{ticketTypeId}")]
    Task DeleteAsync(string ticketTypeId);
}
