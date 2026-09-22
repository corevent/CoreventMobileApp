using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using Moq;
using Refit;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class FavoritesServiceTests
{
    private readonly Mock<IFavoritesApi> _apiMock;
    private readonly FavoritesService _service;

    public FavoritesServiceTests()
    {
        _apiMock = new Mock<IFavoritesApi>();
        _service = new FavoritesService(_apiMock.Object);
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
        _apiMock.Setup(a => a.CreateAsync("evt_1"))
            .ReturnsAsync(new FavoriteResponseDto(new FavoriteDataDto("fav_new", "u1", "evt_1")));

        var result = await _service.AddFavoriteAsync("evt_1");

        result.ShouldNotBeNull();
        result.Id.ShouldBe("fav_new");
        _service.IsFavorite("evt_1").ShouldBeTrue();
        _service.GetFavoriteId("evt_1").ShouldBe("fav_new");
    }

    [Fact]
    public async Task AddFavoriteAsync_ShouldReturnNull_OnApiError()
    {
        _apiMock.Setup(a => a.CreateAsync("evt_error")).ThrowsAsync(new HttpRequestException("boom"));

        var result = await _service.AddFavoriteAsync("evt_error");

        result.ShouldBeNull();
        _service.IsFavorite("evt_error").ShouldBeFalse();
    }

    [Fact]
    public async Task RemoveFavoriteAsync_ShouldCallDeleteAndRemoveFromCache_WhenFavoriteExists()
    {
        _service.SetFavoriteIdByEventId("evt_1", "fav_123");
        _apiMock.Setup(a => a.DeleteAsync("fav_123")).Returns(Task.CompletedTask);

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

    [Fact]
    public async Task RemoveFavoriteAsync_ShouldReturnFalse_OnApiError()
    {
        _service.SetFavoriteIdByEventId("evt_1", "fav_123");
        _apiMock.Setup(a => a.DeleteAsync("fav_123")).ThrowsAsync(new HttpRequestException("boom"));

        var success = await _service.RemoveFavoriteAsync("evt_1");

        success.ShouldBeFalse();
        _service.IsFavorite("evt_1").ShouldBeTrue();
    }
}
