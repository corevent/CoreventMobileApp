using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class ParticipantsServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly ParticipantsApiClient _api;
    private readonly ParticipantsService _service;

    public ParticipantsServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new ParticipantsApiClient(httpClient);
        _service = new ParticipantsService(_api);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnParticipants_OnSuccess()
    {
        var json = "{\"data\":[{\"id\":\"usr_1\",\"name\":\"Lucas Silva\",\"email\":\"lucas@example.com\",\"ticketsCount\":2}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"currentPage\":1,\"itemsPerPage\":100}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/participants*")
            .Respond("application/json", json);

        var result = await _service.GetAllAsync("evt_1", 1, 100);

        result.ShouldNotBeNull();
        result.Data.Count.ShouldBe(1);
        result.Data[0].Name.ShouldBe("Lucas Silva");
        result.Data[0].TicketsCount.ShouldBe(2);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnEmptyList_OnError()
    {
        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/participants*")
            .Respond(HttpStatusCode.InternalServerError);

        var result = await _service.GetAllAsync("evt_1", 1, 100);

        result.ShouldNotBeNull();
        result.Data.ShouldBeEmpty();
    }
}
