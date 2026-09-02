using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class EventRatingsServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly EventRatingsApiClient _api;
    private readonly EventRatingsService _service;

    public EventRatingsServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new EventRatingsApiClient(httpClient);
        _service = new EventRatingsService(_api);
    }

    [Fact]
    public async Task GetMyRatingsAsync_ShouldReturnRatings_OnSuccess()
    {
        var json = "{\"data\":[{\"eventId\":\"evt_1\",\"eventTitle\":\"Rock Fest\",\"bannerUrl\":\"https://cdn.example.com/banner.png\",\"averageRating\":4.8,\"userRating\":5}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":50}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/event-ratings/my-ratings*")
            .Respond("application/json", json);

        var result = await _service.GetMyRatingsAsync(1, 50);

        result.ShouldNotBeNull();
        result.Data.Count.ShouldBe(1);
        result.Data[0].EventId.ShouldBe("evt_1");
        result.Data[0].EventTitle.ShouldBe("Rock Fest");
        result.Data[0].UserRating.ShouldBe(5);
        result.Data[0].AverageRating.ShouldBe(4.8);
    }
}
