using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IEventsApi
{
    [Post("/api/events")]
    Task<EventResponseDto> CreateAsync([Body] CreateEventDto dto);

    [Get("/api/events")]
    Task<EventListPageDto> GetAllAsync(
        int page = 1, int limit = 10,
        string? search = null,
        string? category = null,
        DateTime? startDate = null,
        string? status = null,
        bool? isAdultOnly = null,
        int? stateId = null,
        int? cityId = null);

    [Get("/api/events/{id}")]
    Task<EventResponseDto> GetByIdAsync(string id);

    [Patch("/api/events/{id}")]
    Task<EventResponseDto> UpdateAsync(string id, [Body] UpdateEventDto dto);

    [Patch("/api/events/{id}")]
    Task<EventResponseDto> UpdatePartialAsync(string id, [Body] Dictionary<string, object?> payload);

    [Patch("/api/events/{id}")]
    Task<EventResponseDto> UpdateStatusAsync(string id, [Body] UpdateEventStatusDto dto);

    [Get("/api/events/my/organizer")]
    Task<EventListPageDto> GetMyOrganizerEventsAsync(
        int page, int limit,
        string status,
        string? search = null,
        string? category = null,
        DateTime? startDate = null,
        bool? isAdultOnly = null,
        int? stateId = null,
        int? cityId = null);

    [Get("/api/events/my/staff")]
    Task<StaffEventListPageDto> GetMyStaffEventsAsync(
        int page, int limit,
        string status,
        string? search = null,
        string? category = null,
        DateTime? startDate = null,
        bool? isAdultOnly = null,
        int? stateId = null,
        int? cityId = null);

    [Delete("/api/events/{id}")]
    Task DeleteAsync(string id);

    [Get("/api/events/my/favorites")]
    Task<EventListPageDto> GetMyFavoriteEventsAsync(
        int page, int limit,
        string status,
        string? search = null,
        string? category = null,
        DateTime? startDate = null,
        bool? isAdultOnly = null,
        int? stateId = null,
        int? cityId = null);

    [Post("/api/events/{id}/cancel")]
    Task CancelAsync(string id);
}
