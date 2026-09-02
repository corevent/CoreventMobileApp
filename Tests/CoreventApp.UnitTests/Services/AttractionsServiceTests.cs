using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class AttractionsServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly AttractionsApiClient _api;
    private readonly AttractionsService _service;

    public AttractionsServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new AttractionsApiClient(httpClient);
        _service = new AttractionsService(_api);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnList_OnSuccess()
    {
        var json = "{\"data\":[{\"id\":\"att_1\",\"eventId\":\"evt_1\",\"title\":\"Banda Principal\",\"description\":\"Show de abertura\",\"startTime\":\"2026-10-10T20:00:00.000Z\",\"endTime\":\"2026-10-10T22:00:00.000Z\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":10}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/attractions*")
            .Respond("application/json", json);

        var result = await _service.GetAllAsync("evt_1", 1, 10);

        result.ShouldNotBeNull();
        result.Data.Count.ShouldBe(1);
        result.Data[0].Title.ShouldBe("Banda Principal");
    }

    [Fact]
    public async Task CreateAsync_ShouldReturnAttraction_OnSuccess()
    {
        var json = "{\"data\":{\"id\":\"att_new\",\"eventId\":\"evt_1\",\"title\":\"DJ Set\",\"description\":\"Eletronica\",\"startTime\":\"2026-10-10T22:00:00.000Z\",\"endTime\":\"2026-10-11T00:00:00.000Z\"}}";

        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/events/evt_1/attractions")
            .Respond("application/json", json);

        var dto = new CreateAttractionDto("DJ Set", "Eletronica", DateTime.UtcNow, DateTime.UtcNow.AddHours(2));
        var result = await _service.CreateAsync("evt_1", dto);

        result.ShouldNotBeNull();
        result.Id.ShouldBe("att_new");
        result.Title.ShouldBe("DJ Set");
    }

    [Fact]
    public async Task DeleteAsync_ShouldReturnTrue_OnSuccess()
    {
        _httpMock.Expect(HttpMethod.Delete, "https://api.corevent.com/api/events/attractions/att_1")
            .Respond(HttpStatusCode.OK);

        var success = await _service.DeleteAsync("att_1");

        success.ShouldBeTrue();
    }
}
