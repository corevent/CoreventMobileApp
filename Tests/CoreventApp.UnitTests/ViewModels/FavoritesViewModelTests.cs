using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class FavoritesViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly EventsService _eventsService;
    private readonly FavoritesService _favoritesService;
    private readonly Mock<IAuthService> _authMock;
    private readonly FavoritesViewModel _vm;

    public FavoritesViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApi = new EventsApiClient(client);
        _eventsService = new EventsService(eventsApi);

        var favApi = new FavoritesApiClient(client);
        _favoritesService = new FavoritesService(favApi);

        _authMock = new Mock<IAuthService>();

        _vm = new FavoritesViewModel(_eventsService, _favoritesService, _authMock.Object);
    }

    [Fact]
    public void InitialState_ShouldHaveEmptyFavorites()
    {
        _vm.FavoriteEvents.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsRefreshing.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadFavoritesAsync_ShouldPopulateFavoritesList()
    {
        var json = "{\"data\":[{\"id\":\"evt_fav_1\",\"title\":\"Jazz Night\",\"maxParticipants\":500,\"cityName\":\"Rio\",\"stateAcronym\":\"RJ\",\"locationName\":\"Clube\",\"startDate\":\"2026-10-10T20:00:00.000Z\",\"endDate\":\"2026-10-10T22:00:00.000Z\",\"category\":\"music\",\"isAdultOnly\":false,\"status\":\"opened\",\"organizer\":{\"id\":\"o1\",\"name\":\"Org\",\"email\":\"o@t.com\",\"avatarUrl\":null},\"favoriteId\":\"fav_1\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":50}}";

        _httpMock.When(HttpMethod.Get, "https://api.corevent.com/api/events/my/favorites*")
            .Respond("application/json", json);

        await _vm.LoadFavoritesCommand.ExecuteAsync(null);

        _vm.FavoriteEvents.Count.ShouldBe(1);
        _vm.FavoriteEvents[0].Title.ShouldBe("Jazz Night");
        _favoritesService.IsFavorite("evt_fav_1").ShouldBeTrue();
    }
}
