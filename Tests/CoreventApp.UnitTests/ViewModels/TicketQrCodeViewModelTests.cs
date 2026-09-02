using CoreventApp.ViewModels;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class TicketQrCodeViewModelTests
{
    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        var vm = new TicketQrCodeViewModel();

        vm.TicketId.ShouldBeEmpty();
        vm.EventTitle.ShouldBeEmpty();
        vm.TicketTypeName.ShouldBeEmpty();
        vm.Price.ShouldBe(0);
        vm.Status.ShouldBeEmpty();
        vm.OrderId.ShouldBeEmpty();
        vm.QrCodeSource.ShouldBeNull();
        vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public void Properties_ShouldUpdateCorrectly()
    {
        var vm = new TicketQrCodeViewModel
        {
            TicketId = "tkt_1",
            EventTitle = "Show Rock",
            TicketTypeName = "VIP",
            Price = 150.0m,
            Status = "paid",
            OrderId = "ord_1"
        };

        vm.TicketId.ShouldBe("tkt_1");
        vm.EventTitle.ShouldBe("Show Rock");
        vm.TicketTypeName.ShouldBe("VIP");
        vm.Price.ShouldBe(150.0m);
        vm.Status.ShouldBe("paid");
        vm.OrderId.ShouldBe("ord_1");
    }
}
