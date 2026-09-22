using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class EventRatingsApiIntegrationTests
{
    private static IEventRatingsApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IEventRatingsApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task GetMyRatingsAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[{\"eventId\":\"evt_1\",\"eventTitle\":\"Rock Fest\",\"bannerUrl\":\"https://cdn.example.com/banner.png\",\"averageRating\":4.8,\"userRating\":5}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":20}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/my/ratings?page=1&limit=20")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetMyRatingsAsync(1, 20);

        result.Data.Count.ShouldBe(1);
        result.Data[0].EventId.ShouldBe("evt_1");
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task CreateAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/events/evt_1/ratings")
            .Respond("application/json", "{\"data\":null}");

        var api = CreateApi(httpMock);

        await api.CreateAsync("evt_1", new CoreventApp.Models.Dtos.CreateEventRatingDto(5));

        httpMock.VerifyNoOutstandingExpectation();
    }
}
