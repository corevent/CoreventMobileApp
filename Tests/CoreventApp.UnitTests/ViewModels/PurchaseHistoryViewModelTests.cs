using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class PurchaseHistoryViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly OrdersService _ordersService;
    private readonly PurchaseHistoryViewModel _vm;

    public PurchaseHistoryViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new OrdersApiClient(client);
        _ordersService = new OrdersService(api);
        _vm = new PurchaseHistoryViewModel(_ordersService);
    }

    [Fact]
    public void InitialState_ShouldBeDefault()
    {
        _vm.Orders.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsEmpty.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadOrders_ShouldPopulateOrdersAndSetIsEmptyFalse()
    {
        var json = "{\"data\":[{\"id\":\"ord_100\",\"event\":{\"id\":\"evt_1\",\"title\":\"Rock Fest\",\"startDate\":\"2026-10-10T19:00:00.000Z\",\"endDate\":\"2026-10-10T23:00:00.000Z\"},\"totalAmount\":250.0,\"status\":\"paid\",\"createdAt\":\"2026-09-01T00:00:00.000Z\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":50}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/my/orders*")
            .Respond("application/json", json);

        await _vm.LoadOrdersCommand.ExecuteAsync(null);

        _vm.Orders.Count.ShouldBe(1);
        _vm.Orders[0].Id.ShouldBe("ord_100");
        _vm.IsEmpty.ShouldBeFalse();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadOrders_ShouldSetIsEmptyTrue_WhenNoOrders()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":50}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/my/orders*")
            .Respond("application/json", json);

        await _vm.LoadOrdersCommand.ExecuteAsync(null);

        _vm.Orders.ShouldBeEmpty();
        _vm.IsEmpty.ShouldBeTrue();
    }
}
