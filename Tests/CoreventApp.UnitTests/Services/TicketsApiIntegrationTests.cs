using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class TicketsApiIntegrationTests
{
    private static ITicketsApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<ITicketsApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task GetMyTicketsAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":100}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/tickets?page=1&limit=100")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetMyTicketsAsync(1, 100);

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task GetMyTicketsAsync_ShouldAppendEventId_WhenProvided()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":100}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/tickets?page=1&limit=100&eventId=evt_1")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetMyTicketsAsync(1, 100, "evt_1");

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task GetMyTicketsByEventAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/my/tickets")
            .Respond("application/json", "{\"data\":[]}");

        var api = CreateApi(httpMock);

        var result = await api.GetMyTicketsByEventAsync("evt_1");

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }
}
