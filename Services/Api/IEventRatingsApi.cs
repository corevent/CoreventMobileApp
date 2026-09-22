using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IEventRatingsApi
{
    [Post("/api/events/{eventId}/ratings")]
    Task<EventRatingResponseDto> CreateAsync(string eventId, [Body] CreateEventRatingDto dto);

    [Patch("/api/events/ratings/{ratingId}")]
    Task UpdateAsync(string ratingId, [Body] CreateEventRatingDto dto);

    [Delete("/api/events/ratings/{ratingId}")]
    Task DeleteAsync(string ratingId);

    [Get("/api/events/my/ratings")]
    Task<MyRatingsListPageDto> GetMyRatingsAsync(int page = 1, int limit = 20);
}
