using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class CheckInServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly CheckInApiClient _api;
    private readonly CheckInService _service;

    public CheckInServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new CheckInApiClient(httpClient);
        _service = new CheckInService(_api);
    }

    [Fact]
    public async Task CheckinAsync_ShouldReturnData_OnSuccess()
    {
        var responseJson = "{\"data\":{\"ticketId\":\"tkt_1\",\"ticketTypeId\":\"tt_1\",\"status\":\"checked_in\",\"checkinAt\":\"2026-09-01T20:30:00.000Z\",\"ticketType\":{\"id\":\"tt_1\",\"name\":\"Geral\",\"price\":50.0},\"event\":{\"id\":\"evt_1\",\"title\":\"Show\"},\"order\":{\"id\":\"ord_1\",\"status\":\"paid\",\"gatewayTransactionId\":\"tx_1\"},\"user\":{\"id\":\"u1\",\"name\":\"Lucas\",\"email\":\"lucas@example.com\"},\"checkedInBy\":{\"id\":\"stf_1\",\"name\":\"Staff\"}}}";

        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/events/evt_1/checkin")
            .Respond("application/json", responseJson);

        var result = await _service.CheckinAsync("evt_1", "qr_token_abc");

        result.ShouldNotBeNull();
        result.TicketId.ShouldBe("tkt_1");
        result.Status.ShouldBe("checked_in");
    }

    [Fact]
    public async Task CheckinAsync_ShouldReturnNull_OnError()
    {
        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/events/evt_1/checkin")
            .Respond(HttpStatusCode.BadRequest, "application/json", "{\"message\":\"Ticket already used\"}");

        var result = await _service.CheckinAsync("evt_1", "invalid_token");

        result.ShouldBeNull();
    }
}
