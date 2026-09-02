using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class TicketsServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly TicketsApiClient _api;
    private readonly TicketsService _service;

    public TicketsServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new TicketsApiClient(httpClient);
        _service = new TicketsService(_api);
    }

    [Fact]
    public async Task GetMyTicketsAsync_ShouldReturnTickets_WhenApiSucceeds()
    {
        var jsonResponse = "{\"data\":[{\"id\":\"tkt_1\",\"status\":\"paid\",\"ticketTypeId\":\"tt_1\",\"eventId\":\"evt_1\",\"userId\":\"u1\",\"qrToken\":\"qr_123\",\"createdAt\":\"2026-09-01T00:00:00.000Z\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":10}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/tickets*")
            .Respond("application/json", jsonResponse);

        var result = await _service.GetMyTicketsAsync(1, 10);

        result.ShouldNotBeNull();
        result.Data.Count.ShouldBe(1);
        result.Data[0].Id.ShouldBe("tkt_1");
        result.Meta.TotalItems.ShouldBe(1);
    }

    [Fact]
    public async Task GetMyTicketsAsync_ShouldReturnEmptyPage_WhenApiFails()
    {
        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/tickets*")
            .Respond(HttpStatusCode.InternalServerError);

        var result = await _service.GetMyTicketsAsync(1, 10);

        result.ShouldNotBeNull();
        result.Data.ShouldBeEmpty();
        result.Meta.TotalItems.ShouldBe(0);
    }
}
