using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ReviewsViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly EventRatingsService _ratingsService;
    private readonly ReviewsViewModel _vm;

    public ReviewsViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new EventRatingsApiClient(client);
        _ratingsService = new EventRatingsService(api);
        _vm = new ReviewsViewModel(_ratingsService);
    }

    [Fact]
    public void InitialState_ShouldBeDefault()
    {
        _vm.Items.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsEmpty.ShouldBeFalse();
        _vm.IsRefreshing.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadItems_ShouldPopulateItemsAndSetIsEmpty()
    {
        var json = "{\"data\":[{\"eventId\":\"evt_1\",\"eventTitle\":\"Show SP\",\"bannerUrl\":\"https://img.com/1.jpg\",\"averageRating\":4.9,\"userRating\":5}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":100}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/event-ratings/my-ratings*")
            .Respond("application/json", json);

        await _vm.LoadItemsCommand.ExecuteAsync(null);

        _vm.Items.Count.ShouldBe(1);
        _vm.Items[0].EventTitle.ShouldBe("Show SP");
        _vm.IsEmpty.ShouldBeFalse();
        _vm.IsLoading.ShouldBeFalse();
    }
}
