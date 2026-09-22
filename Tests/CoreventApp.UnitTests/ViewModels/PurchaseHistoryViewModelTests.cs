using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class PurchaseHistoryViewModelTests
{
    private readonly Mock<IOrdersApi> _ordersApiMock;
    private readonly PurchaseHistoryViewModel _vm;

    public PurchaseHistoryViewModelTests()
    {
        _ordersApiMock = new Mock<IOrdersApi>();
        _vm = new PurchaseHistoryViewModel(_ordersApiMock.Object);
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
        var evt = new OrderEventDto("evt_1", "Rock Fest",
            new DateTime(2026, 10, 10, 19, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 10, 10, 23, 0, 0, DateTimeKind.Utc));
        var order = new MyOrdersDataDto("ord_100", evt, 250.0m, "paid",
            new DateTime(2026, 9, 1, 0, 0, 0, DateTimeKind.Utc));

        _ordersApiMock.Setup(a => a.GetMyOrdersAsync(1, 50))
            .ReturnsAsync(new PaginateMyOrdersDto(new List<MyOrdersDataDto> { order }, new PaginationMetaDto(1, 1, 1, 50)));

        await _vm.LoadOrdersCommand.ExecuteAsync(null);

        _vm.Orders.Count.ShouldBe(1);
        _vm.Orders[0].Id.ShouldBe("ord_100");
        _vm.IsEmpty.ShouldBeFalse();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadOrders_ShouldSetIsEmptyTrue_WhenNoOrders()
    {
        _ordersApiMock.Setup(a => a.GetMyOrdersAsync(1, 50))
            .ReturnsAsync(new PaginateMyOrdersDto(new List<MyOrdersDataDto>(), new PaginationMetaDto(0, 0, 1, 50)));

        await _vm.LoadOrdersCommand.ExecuteAsync(null);

        _vm.Orders.ShouldBeEmpty();
        _vm.IsEmpty.ShouldBeTrue();
    }
}
