using System.Collections.Concurrent;
using System.Diagnostics;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;

namespace CoreventApp.Services;

public class FavoritesService
{
    private readonly IFavoritesApi _api;
    private readonly ConcurrentDictionary<string, string> _favoriteIdByEventId = new();

    public FavoritesService(IFavoritesApi api)
    {
        _api = api;
    }

    public bool IsFavorite(string eventId)
    {
        return _favoriteIdByEventId.ContainsKey(eventId);
    }

    public string? GetFavoriteId(string eventId)
    {
        return _favoriteIdByEventId.TryGetValue(eventId, out var favoriteId) ? favoriteId : null;
    }

    public void SetFavorites(IEnumerable<EventListItemDto> events)
    {
        _favoriteIdByEventId.Clear();
        foreach (var ev in events)
        {
            _favoriteIdByEventId.TryAdd(ev.Id, ev.FavoriteId ?? string.Empty);
        }
    }

    public void SetFavoriteIdByEventId(string eventId, string favoriteId)
    {
        _favoriteIdByEventId[eventId] = favoriteId;
    }

    public void RemoveFromCache(string eventId)
    {
        _favoriteIdByEventId.TryRemove(eventId, out _);
    }

    public void ClearCache()
    {
        _favoriteIdByEventId.Clear();
    }

    public async Task<FavoriteDataDto?> AddFavoriteAsync(string eventId)
    {
        var result = await ApiResult.TryExecuteAsync(() => _api.CreateAsync(eventId), "Add favorite");
        if (result is null)
            return null;

        _favoriteIdByEventId[eventId] = result.Data.Id;
        return result.Data;
    }

    public async Task<bool> RemoveFavoriteAsync(string eventId)
    {
        var favoriteId = GetFavoriteId(eventId);
        if (favoriteId is null) return false;

        var removed = await ApiResult.TryExecuteAsync(() => _api.DeleteAsync(favoriteId), "Remove favorite");
        if (!removed) return false;

        _favoriteIdByEventId.TryRemove(eventId, out _);
        return true;
    }
}
