using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IFavoritesApi
{
    [Post("/api/favorites/events/{eventId}")]
    Task<FavoriteResponseDto> CreateAsync(string eventId);

    [Delete("/api/favorites/{favoriteId}")]
    Task DeleteAsync(string favoriteId);
}
