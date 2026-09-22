using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ManageTicketsViewModelTests
{
    private readonly ManageTicketsViewModel _vm;

    public ManageTicketsViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var ticketTypesApiMock = new Mock<ITicketTypesApi>();
        var eventsApiMock = new Mock<IEventsApi>();

        _vm = new ManageTicketsViewModel(ticketTypesApiMock.Object, eventsApiMock.Object, new CoreventApp.Services.DialogService());
    }

    [Fact]
    public void InitialState_ShouldBeCreatingMode()
    {
        _vm.IsEditing.ShouldBeFalse();
        _vm.FormTitle.ShouldBe("Novo Tipo de Ingresso");
        _vm.FormButtonText.ShouldBe("Adicionar");
        _vm.NewName.ShouldBeEmpty();
        _vm.NewPrice.ShouldBeEmpty();
        _vm.NewTotalQuantity.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public void SettingEditingTicketId_ShouldSwitchToEditMode()
    {
        _vm.EditingTicketId = "tt_123";

        _vm.IsEditing.ShouldBeTrue();
        _vm.FormTitle.ShouldBe("Editar Ingresso");
        _vm.FormButtonText.ShouldBe("Salvar");
    }

    [Fact]
    public void TicketTypeViewModel_FormattingProperties_ShouldWork()
    {
        var item = new TicketTypeViewModel
        {
            Id = "tt_1",
            Name = "Pista Premium",
            Price = 120.50m,
            TotalQuantity = 100,
            AvailableQuantity = 45,
            StartDate = new DateTime(2026, 10, 1),
            EndDate = new DateTime(2026, 10, 10)
        };

        item.FormattedPrice.ShouldBe("R$ 120,50");
        item.AvailableLabel.ShouldBe("45 ingressos disponíveis");
        item.FormattedPeriod.ShouldContain("01/10/2026");
        item.FormattedPeriod.ShouldContain("10/10/2026");
    }

    [Fact]
    public void EditTicketType_And_CancelEdit_ShouldPopulateAndResetForm()
    {
        var item = new TicketTypeViewModel
        {
            Id = "tt_2",
            Name = "VIP",
            Price = 250.0m,
            TotalQuantity = 50,
            AvailableQuantity = 50,
            StartDate = new DateTime(2026, 11, 1),
            EndDate = new DateTime(2026, 11, 10)
        };

        _vm.EditTicketTypeCommand.Execute(item);

        _vm.IsEditing.ShouldBeTrue();
        _vm.EditingTicketId.ShouldBe("tt_2");
        _vm.NewName.ShouldBe("VIP");
        _vm.NewPrice.ShouldBe("250,00");
        _vm.NewTotalQuantity.ShouldBe("50");

        _vm.CancelEditCommand.Execute(null);

        _vm.IsEditing.ShouldBeFalse();
        _vm.EditingTicketId.ShouldBeNull();
        _vm.NewName.ShouldBeEmpty();
    }
}
