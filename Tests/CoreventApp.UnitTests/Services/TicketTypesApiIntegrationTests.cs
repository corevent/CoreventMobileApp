using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class TicketTypesApiIntegrationTests
{
    private static ITicketTypesApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<ITicketTypesApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task GetAllAsync_ShouldFormatBoolsLowercase()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"currentPage\":1,\"itemsPerPage\":10}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/ticket-types?page=1&limit=10&availableOnly=true")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetAllAsync("evt_1", availableOnly: true);

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task GetAllAsync_ShouldFormatDatesWithTimestamp()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"currentPage\":1,\"itemsPerPage\":10}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/ticket-types?page=1&limit=10&availableOnly=false&startDate=2026-05-01T19%3A00%3A00.000Z&endDate=2026-05-10T19%3A00%3A00.000Z")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetAllAsync("evt_1",
            startDate: new DateTime(2026, 5, 1, 19, 0, 0, DateTimeKind.Utc),
            endDate: new DateTime(2026, 5, 10, 19, 0, 0, DateTimeKind.Utc));

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }
}
