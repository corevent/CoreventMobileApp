using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IEventStaffApi
{
    [Get("/api/events/{eventId}/staff")]
    Task<PaginateEventStaffDto> GetAllAsync(
        string eventId,
        int page = 1, int limit = 10,
        string? name = null,
        string? email = null,
        string? invitationStatus = null,
        string? accessLevel = null);

    [Get("/api/events/staff/{staffId}")]
    Task<EventStaffResponseDto> GetByIdAsync(string staffId);

    [Delete("/api/events/staff/{staffId}")]
    Task DeleteAsync(string staffId);

    [Patch("/api/events/{staffId}/access-level")]
    Task<EventStaffResponseDto> UpdateAccessLevelAsync(string staffId, [Body] UpdateEventStaffAccessLevelDto dto);
}
