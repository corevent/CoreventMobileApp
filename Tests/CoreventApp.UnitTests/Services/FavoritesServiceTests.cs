using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class FavoritesServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly FavoritesApiClient _api;
    private readonly FavoritesService _service;

    public FavoritesServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new FavoritesApiClient(httpClient);
        _service = new FavoritesService(_api);
    }

    [Fact]
    public void CacheManagement_ShouldTrackFavoriteStatus()
    {
        _service.IsFavorite("evt_1").ShouldBeFalse();
        _service.GetFavoriteId("evt_1").ShouldBeNull();

        _service.SetFavoriteIdByEventId("evt_1", "fav_100");

        _service.IsFavorite("evt_1").ShouldBeTrue();
        _service.GetFavoriteId("evt_1").ShouldBe("fav_100");

        _service.RemoveFromCache("evt_1");
        _service.IsFavorite("evt_1").ShouldBeFalse();

        _service.SetFavoriteIdByEventId("evt_2", "fav_200");
        _service.ClearCache();
        _service.IsFavorite("evt_2").ShouldBeFalse();
    }

    [Fact]
    public async Task AddFavoriteAsync_ShouldCallApiAndCacheId_OnSuccess()
    {
        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/favorites/events/evt_1")
            .Respond("application/json", "{\"data\":{\"id\":\"fav_new\",\"userId\":\"u1\",\"eventId\":\"evt_1\",\"createdAt\":\"2026-09-01T00:00:00.000Z\"}}");

        var result = await _service.AddFavoriteAsync("evt_1");

        result.ShouldNotBeNull();
        result.Id.ShouldBe("fav_new");
        _service.IsFavorite("evt_1").ShouldBeTrue();
        _service.GetFavoriteId("evt_1").ShouldBe("fav_new");
    }

    [Fact]
    public async Task AddFavoriteAsync_ShouldReturnNull_OnApiError()
    {
        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/favorites/events/evt_error")
            .Respond(HttpStatusCode.InternalServerError);

        var result = await _service.AddFavoriteAsync("evt_error");

        result.ShouldBeNull();
        _service.IsFavorite("evt_error").ShouldBeFalse();
    }

    [Fact]
    public async Task RemoveFavoriteAsync_ShouldCallDeleteAndRemoveFromCache_WhenFavoriteExists()
    {
        _service.SetFavoriteIdByEventId("evt_1", "fav_123");

        _httpMock.Expect(HttpMethod.Delete, "https://api.corevent.com/api/favorites/fav_123")
            .Respond(HttpStatusCode.OK);

        var success = await _service.RemoveFavoriteAsync("evt_1");

        success.ShouldBeTrue();
        _service.IsFavorite("evt_1").ShouldBeFalse();
    }

    [Fact]
    public async Task RemoveFavoriteAsync_ShouldReturnFalse_WhenNotInCache()
    {
        var success = await _service.RemoveFavoriteAsync("evt_not_cached");

        success.ShouldBeFalse();
    }
}
