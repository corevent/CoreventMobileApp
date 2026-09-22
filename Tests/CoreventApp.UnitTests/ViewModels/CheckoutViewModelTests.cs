using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class CheckoutViewModelTests
{
    private readonly CheckoutViewModel _vm;

    public CheckoutViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApiMock = new Mock<IEventsApi>();
        var ticketTypesApiMock = new Mock<ITicketTypesApi>();
        var ordersApiMock = new Mock<IOrdersApi>();
        var agePoliciesApi = new AgePoliciesApiClient(client);
        var agePolicyService = new AgePolicyService(agePoliciesApi);

        _vm = new CheckoutViewModel(eventsApiMock.Object, ticketTypesApiMock.Object, ordersApiMock.Object, agePolicyService);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.Quantity.ShouldBe(1);
        _vm.HasMinQuantity.ShouldBeTrue();
        _vm.HasReachedMaxQuantity.ShouldBeFalse();
        _vm.Subtotal.ShouldBe(0);
        _vm.Total.ShouldBe(0);
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsPurchasing.ShouldBeFalse();
    }

    [Fact]
    public void SelectTicketTypeCommand_ShouldSelectAndResetQuantity()
    {
        var tt1 = new TicketTypeDataDto("tt_1", "evt_1", "Pista", 50.0m, 100, 50, DateTime.UtcNow, DateTime.UtcNow.AddDays(5));
        var tt2 = new TicketTypeDataDto("tt_2", "evt_1", "Camarote", 120.0m, 100, 20, DateTime.UtcNow, DateTime.UtcNow.AddDays(5));

        var sel1 = new SelectableTicketType(tt1);
        var sel2 = new SelectableTicketType(tt2);

        _vm.SelectTicketTypeCommand.Execute(sel1);
        _vm.SelectedTicketType.ShouldBe(sel1);
        sel1.IsSelected.ShouldBeTrue();

        _vm.Quantity = 5;

        _vm.SelectTicketTypeCommand.Execute(sel2);
        _vm.SelectedTicketType.ShouldBe(sel2);
        sel2.IsSelected.ShouldBeTrue();
        sel1.IsSelected.ShouldBeFalse();
        _vm.Quantity.ShouldBe(1);
    }

    [Fact]
    public void IncreaseAndDecreaseQuantityCommands_ShouldRespectAvailableBounds()
    {
        var tt = new TicketTypeDataDto("tt_1", "evt_1", "Vip", 100.0m, 10, 3, DateTime.UtcNow, DateTime.UtcNow.AddDays(5));
        var sel = new SelectableTicketType(tt);

        _vm.SelectedTicketType = sel;
        _vm.Quantity = 1;

        _vm.IncreaseQuantityCommand.Execute(null);
        _vm.Quantity.ShouldBe(2);

        _vm.IncreaseQuantityCommand.Execute(null);
        _vm.Quantity.ShouldBe(3);
        _vm.HasReachedMaxQuantity.ShouldBeTrue();

        // Should not exceed 3
        _vm.IncreaseQuantityCommand.Execute(null);
        _vm.Quantity.ShouldBe(3);

        // Decrease
        _vm.DecreaseQuantityCommand.Execute(null);
        _vm.Quantity.ShouldBe(2);

        _vm.DecreaseQuantityCommand.Execute(null);
        _vm.Quantity.ShouldBe(1);
        _vm.HasMinQuantity.ShouldBeTrue();

        // Should not go below 1
        _vm.DecreaseQuantityCommand.Execute(null);
        _vm.Quantity.ShouldBe(1);
    }
}
