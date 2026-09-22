using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class TicketsViewModelTests
{
    private readonly Mock<ITicketsApi> _ticketsApiMock;
    private readonly TicketsViewModel _vm;

    public TicketsViewModelTests()
    {
        _ticketsApiMock = new Mock<ITicketsApi>();

        _vm = new TicketsViewModel(_ticketsApiMock.Object);
    }

    [Fact]
    public void InitialState_ShouldHaveProximosVisibleAndEmptyLists()
    {
        _vm.IsProximosVisible.ShouldBeTrue();
        _vm.IsPassadosVisible.ShouldBeFalse();
        _vm.ProximosTickets.ShouldBeEmpty();
        _vm.PassadosTickets.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public void SelectPassadosAndProximos_ShouldToggleTabVisibility()
    {
        _vm.SelectPassados();
        _vm.IsProximosVisible.ShouldBeFalse();
        _vm.IsPassadosVisible.ShouldBeTrue();

        _vm.SelectProximos();
        _vm.IsProximosVisible.ShouldBeTrue();
        _vm.IsPassadosVisible.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadTickets_ShouldCategorizeTicketsByStatus()
    {
        var t1 = new UserTicketDataDto("t1", "e1", "tt1", "paid", null, "qr1",
            new UserTicketTypeDto("tt1", "Pista", 50.0m),
            new UserTicketEventDto("e1", "Rock Fest"),
            new UserTicketOrderDto("o1", "paid"));
        var t2 = new UserTicketDataDto("t2", "e2", "tt2", "used", null, "qr2",
            new UserTicketTypeDto("tt2", "Camarote", 100.0m),
            new UserTicketEventDto("e2", "Jazz Night"),
            new UserTicketOrderDto("o2", "paid"));

        _ticketsApiMock.Setup(a => a.GetMyTicketsAsync(1, 100, null))
            .ReturnsAsync(new PaginateMyTicketsDto(
                new List<UserTicketDataDto> { t1, t2 }, new PaginationMetaDto(2, 1, 1, 100)));

        await _vm.LoadTicketsCommand.ExecuteAsync(null);

        _vm.ProximosTickets.Count.ShouldBe(1);
        _vm.ProximosTickets[0].Id.ShouldBe("t1");
        _vm.PassadosTickets.Count.ShouldBe(1);
        _vm.PassadosTickets[0].Id.ShouldBe("t2");
        _vm.IsEmptyProximos.ShouldBeFalse();
        _vm.IsEmptyPassados.ShouldBeFalse();
    }
}
