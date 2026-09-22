using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IAttractionsApi
{
    [Post("/api/events/{eventId}/attractions")]
    Task<AttractionResponseDto> CreateAsync(string eventId, [Body] CreateAttractionDto dto);

    [Get("/api/events/{eventId}/attractions")]
    Task<AttractionListPageDto> GetAllAsync(
        string eventId,
        int page = 1, int limit = 10,
        string? search = null,
        string? guest = null,
        DateTime? startDate = null,
        DateTime? endDate = null);

    [Get("/api/events/attractions/{attractionId}")]
    Task<AttractionResponseDto> GetByIdAsync(string attractionId);

    [Patch("/api/events/attractions/{attractionId}")]
    Task<AttractionResponseDto> UpdateAsync(string attractionId, [Body] UpdateAttractionDto dto);

    [Delete("/api/events/attractions/{attractionId}")]
    Task DeleteAsync(string attractionId);
}
