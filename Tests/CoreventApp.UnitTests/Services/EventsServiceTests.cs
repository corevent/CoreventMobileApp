using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class EventsServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly EventsApiClient _eventsApi;
    private readonly EventsService _eventsService;

    public EventsServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _eventsApi = new EventsApiClient(httpClient);
        _eventsService = new EventsService(_eventsApi);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnEventsList_WhenApiSucceeds()
    {
        var responseJson = "{\"data\":[{\"id\":\"evt1\",\"title\":\"Festival de Jazz\",\"description\":\"Show ao vivo\",\"startDate\":\"2026-10-01T20:00:00.000Z\",\"status\":\"opened\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":10}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events*")
            .Respond("application/json", responseJson);

        var result = await _eventsService.GetAllAsync(page: 1, limit: 10);

        result.ShouldNotBeNull();
        result.Data.Count.ShouldBe(1);
        result.Data[0].Id.ShouldBe("evt1");
        result.Data[0].Title.ShouldBe("Festival de Jazz");
        result.Meta.TotalItems.ShouldBe(1);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnEmptyPage_WhenApiThrowsException()
    {
        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events*")
            .Respond(HttpStatusCode.InternalServerError);

        var result = await _eventsService.GetAllAsync(page: 1, limit: 10);

        result.ShouldNotBeNull();
        result.Data.ShouldBeEmpty();
        result.Meta.Page.ShouldBe(1);
        result.Meta.TotalItems.ShouldBe(0);
    }
}
