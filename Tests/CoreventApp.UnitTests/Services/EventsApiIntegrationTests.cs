using System.Net;
using System.Text;
using System.Text.Json;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class EventsApiIntegrationTests
{
    private static IEventsApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IEventsApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task GetAllAsync_ShouldFormatQueryLikeManualClient()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events?page=1&limit=10&startDate=2026-05-01&status=opened&isAdultOnly=false")
            .Respond("application/json", "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":10}}");

        var api = CreateApi(httpMock);

        var result = await api.GetAllAsync(1, 10, startDate: new DateTime(2026, 5, 1), status: "opened", isAdultOnly: false);

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task CreateAsync_ShouldSerializeBodyLikeManualClient()
    {
        string? capturedBody = null;
        var httpMock = new MockHttpMessageHandler();
        httpMock.When(HttpMethod.Post, "https://api.corevent.com/api/events")
            .Respond(async req =>
            {
                capturedBody = req.Content is null ? null : await req.Content.ReadAsStringAsync();
                return new HttpResponseMessage(HttpStatusCode.Created)
                {
                    Content = new StringContent("{\"data\":null}", Encoding.UTF8, "application/json")
                };
            });

        var api = CreateApi(httpMock);
        var dto = new CreateEventDto("Show", "Desc", 100, "in_person", "Arena", 1, "01310",
            "Centro", "Rua A", 100, null, new DateTime(2026, 5, 1, 19, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 5, 1, 23, 0, 0, DateTimeKind.Utc), "music", false, "draft");

        await api.CreateAsync(dto);

        capturedBody.ShouldBe(JsonSerializer.Serialize(dto, JsonConfig.Options));
    }

    [Fact]
    public async Task UpdatePartialAsync_ShouldSerializeDictionaryLikeManualClient()
    {
        string? capturedBody = null;
        var httpMock = new MockHttpMessageHandler();
        httpMock.When(new HttpMethod("PATCH"), "https://api.corevent.com/api/events/evt_1")
            .Respond(async req =>
            {
                capturedBody = req.Content is null ? null : await req.Content.ReadAsStringAsync();
                return new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent("{\"data\":null}", Encoding.UTF8, "application/json")
                };
            });

        var api = CreateApi(httpMock);
        var payload = new Dictionary<string, object?> { ["title"] = "Novo", ["cityId"] = (object?)null };

        await api.UpdatePartialAsync("evt_1", payload);

        capturedBody.ShouldBe(JsonSerializer.Serialize(payload, JsonConfig.Options));
    }

    [Fact]
    public async Task CancelAsync_ShouldPostWithoutBody()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/events/evt_1/cancel")
            .Respond(HttpStatusCode.OK);

        var api = CreateApi(httpMock);

        await api.CancelAsync("evt_1");

        httpMock.VerifyNoOutstandingExpectation();
    }
}
