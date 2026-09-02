using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class HomeViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly EventsService _eventsService;
    private readonly Mock<IAuthService> _authMock;
    private readonly HomeViewModel _vm;

    public HomeViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new EventsApiClient(client);
        _eventsService = new EventsService(api);
        _authMock = new Mock<IAuthService>();

        _vm = new HomeViewModel(_eventsService, _authMock.Object);
    }

    [Fact]
    public void InitialState_ShouldHaveEmptyEventsAndNotLoading()
    {
        _vm.IsLoading.ShouldBeFalse();
        _vm.HighlightedEvents.ShouldBeEmpty();
        _vm.OtherEvents.ShouldBeEmpty();
    }

    [Fact]
    public async Task LoadAsync_ShouldSeparateHighlightedAndOtherEvents()
    {
        var organizer = "{\"id\":\"org_1\",\"name\":\"Org\",\"email\":\"org@test.com\",\"avatarUrl\":null}";
        var eventsList = new List<string>();
        for (int i = 1; i <= 7; i++)
        {
            eventsList.Add($"{{\"id\":\"evt_{i}\",\"title\":\"Show {i}\",\"maxParticipants\":1000,\"cityName\":\"SP\",\"stateAcronym\":\"SP\",\"locationName\":\"Arena\",\"startDate\":\"2026-10-10T20:00:00.000Z\",\"endDate\":\"2026-10-10T23:00:00.000Z\",\"category\":\"music\",\"isAdultOnly\":false,\"status\":\"opened\",\"organizer\":{organizer},\"locationType\":\"in_person\",\"averageRating\":4.5}}");
        }
        var json = $"{{\"data\":[{string.Join(",", eventsList)}],\"meta\":{{\"totalItems\":7,\"totalPages\":1,\"page\":1,\"limit\":50}}}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events*")
            .Respond("application/json", json);

        await _vm.LoadCommand.ExecuteAsync(null);

        _vm.HighlightedEvents.Count.ShouldBe(5);
        _vm.OtherEvents.Count.ShouldBe(2);
        _vm.IsLoading.ShouldBeFalse();
    }
}
