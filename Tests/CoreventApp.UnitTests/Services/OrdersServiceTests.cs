using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class OrdersServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly OrdersApiClient _api;
    private readonly OrdersService _service;

    public OrdersServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new OrdersApiClient(httpClient);
        _service = new OrdersService(_api);
    }

    [Fact]
    public async Task GetMyOrdersAsync_ShouldReturnOrders_WhenApiSucceeds()
    {
        var jsonResponse = "{\"data\":[{\"id\":\"ord_1\",\"event\":{\"id\":\"evt_1\",\"title\":\"Rock Fest\",\"startDate\":\"2026-10-10T19:00:00.000Z\",\"endDate\":\"2026-10-10T23:00:00.000Z\"},\"totalAmount\":150.0,\"status\":\"paid\",\"createdAt\":\"2026-09-01T00:00:00.000Z\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":20}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/orders/my-orders*")
            .Respond("application/json", jsonResponse);

        var result = await _service.GetMyOrdersAsync(1, 20);

        result.ShouldNotBeNull();
        result.Data.Count.ShouldBe(1);
        result.Data[0].Id.ShouldBe("ord_1");
        result.Data[0].TotalAmount.ShouldBe(150.0m);
        result.Data[0].Event.Title.ShouldBe("Rock Fest");
    }

    [Fact]
    public async Task GetMyOrdersAsync_ShouldReturnEmpty_WhenApiFails()
    {
        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/orders/my-orders*")
            .Respond(HttpStatusCode.InternalServerError);

        var result = await _service.GetMyOrdersAsync(1, 20);

        result.ShouldNotBeNull();
        result.Data.ShouldBeEmpty();
    }
}
