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

public class OrdersApiIntegrationTests
{
    private static IOrdersApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IOrdersApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task GetMyOrdersAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":20}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/my/orders?page=1&limit=20")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetMyOrdersAsync(1, 20);

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task GetByIdAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/orders/ord_1")
            .Respond("application/json", "{\"data\":null}");

        var api = CreateApi(httpMock);

        await api.GetByIdAsync("ord_1");

        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task CreateAsync_ShouldSerializeBodyLikeManualClient()
    {
        string? capturedBody = null;
        var httpMock = new MockHttpMessageHandler();
        httpMock.When(HttpMethod.Post, "https://api.corevent.com/api/events/evt_1/orders")
            .Respond(async req =>
            {
                capturedBody = req.Content is null ? null : await req.Content.ReadAsStringAsync();
                return new HttpResponseMessage(HttpStatusCode.Created)
                {
                    Content = new StringContent("{\"data\":null}", Encoding.UTF8, "application/json")
                };
            });

        var api = CreateApi(httpMock);
        var dto = new CreateOrderDto(new List<ItemsDto> { new("tt_1", 2) });

        await api.CreateAsync("evt_1", dto);

        capturedBody.ShouldBe(JsonSerializer.Serialize(dto, JsonConfig.Options));
    }
}
