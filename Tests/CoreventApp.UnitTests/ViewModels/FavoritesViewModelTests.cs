using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class FavoritesViewModelTests
{
    private readonly Mock<IEventsApi> _eventsApiMock;
    private readonly FavoritesService _favoritesService;
    private readonly Mock<IAuthService> _authMock;
    private readonly FavoritesViewModel _vm;

    public FavoritesViewModelTests()
    {
        _eventsApiMock = new Mock<IEventsApi>();

        var favApi = new FavoritesApiClient(new HttpClient());
        _favoritesService = new FavoritesService(favApi);

        _authMock = new Mock<IAuthService>();

        _vm = new FavoritesViewModel(_eventsApiMock.Object, _favoritesService, _authMock.Object);
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
        var organizer = new OrganizerInfoDto("o1", "Org", "o@t.com", null);
        var item = new EventListItemDto("evt_fav_1", "Jazz Night", 500, "Rio", "RJ", "Clube",
            new DateTime(2026, 10, 10, 20, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 10, 10, 22, 0, 0, DateTimeKind.Utc),
            "music", false, "opened", organizer, null, null, "fav_1");
        var empty = new EventListPageDto(new List<EventListItemDto>(), new PaginationMetaDto(0, 0, 1, 100));

        _eventsApiMock.Setup(a => a.GetMyFavoriteEventsAsync(1, 100, "opened", null, null, null, null, null, null))
            .ReturnsAsync(new EventListPageDto(new List<EventListItemDto> { item }, new PaginationMetaDto(1, 1, 1, 100)));
        _eventsApiMock.Setup(a => a.GetMyFavoriteEventsAsync(1, 100, "going", null, null, null, null, null, null))
            .ReturnsAsync(empty);
        _eventsApiMock.Setup(a => a.GetMyFavoriteEventsAsync(1, 100, "finished", null, null, null, null, null, null))
            .ReturnsAsync(empty);

        await _vm.LoadFavoritesCommand.ExecuteAsync(null);

        _vm.FavoriteEvents.Count.ShouldBe(1);
        _vm.FavoriteEvents[0].Title.ShouldBe("Jazz Night");
        _favoritesService.IsFavorite("evt_fav_1").ShouldBeTrue();
    }
}
