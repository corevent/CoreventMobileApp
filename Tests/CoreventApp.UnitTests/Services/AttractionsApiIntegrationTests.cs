using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class AttractionsApiIntegrationTests
{
    private static IAttractionsApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IAttractionsApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task GetAllAsync_ShouldFormatDatesLikeManualClient()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":10}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/attractions?page=1&limit=10&startDate=2026-05-01&endDate=2026-05-10")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetAllAsync("evt_1",
            startDate: new DateTime(2026, 5, 1), endDate: new DateTime(2026, 5, 10));

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task GetByIdAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/attractions/att_1")
            .Respond("application/json", "{\"data\":null}");

        var api = CreateApi(httpMock);

        await api.GetByIdAsync("att_1");

        httpMock.VerifyNoOutstandingExpectation();
    }
}
