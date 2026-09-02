using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class PanelOrganizerViewModelTests
{
    private readonly PanelOrganizerViewModel _vm;

    public PanelOrganizerViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApi = new EventsApiClient(client);
        var eventsService = new EventsService(eventsApi);

        var paymentInfoApi = new PaymentInfoApiClient(client);
        var paymentInfoService = new PaymentInfoService(paymentInfoApi);

        _vm = new PanelOrganizerViewModel(eventsService, paymentInfoService);
    }

    [Fact]
    public void InitialState_ShouldHaveFilterChipsAndDefaultSelection()
    {
        _vm.FilterChips.Count.ShouldBe(6);
        _vm.FilterChips[0].Label.ShouldBe("Todos");
        _vm.FilterChips[0].IsSelected.ShouldBeTrue();
        _vm.AllEvents.ShouldBeEmpty();
        _vm.FilteredEvents.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.HasPaymentInfo.ShouldBeFalse();
    }

    [Fact]
    public void FilterByStatus_ShouldFilterEventsAndSelectChip()
    {
        var organizer = new OrganizerInfoDto("o1", "Org", "o@t.com", null);
        var e1 = new EventListItemDto("e1", "Evento 1", 100, "SP", "SP", "Arena", DateTime.UtcNow, DateTime.UtcNow.AddHours(2), "music", false, "draft", organizer, "in_person", 4.5);
        var e2 = new EventListItemDto("e2", "Evento 2", 200, "SP", "SP", "Arena", DateTime.UtcNow, DateTime.UtcNow.AddHours(2), "tech", false, "opened", organizer, "in_person", 4.8);

        _vm.AllEvents.Add(e1);
        _vm.AllEvents.Add(e2);

        var draftChip = _vm.FilterChips.First(c => c.StatusValue == "draft");
        _vm.FilterByStatusCommand.Execute(draftChip);

        _vm.FilteredEvents.Count.ShouldBe(1);
        _vm.FilteredEvents[0].Id.ShouldBe("e1");

        var openedChip = _vm.FilterChips.First(c => c.StatusValue == "opened");
        _vm.FilterByStatusCommand.Execute(openedChip);

        _vm.FilteredEvents.Count.ShouldBe(1);
        _vm.FilteredEvents[0].Id.ShouldBe("e2");

        var allChip = _vm.FilterChips.First(c => c.StatusValue == null);
        _vm.FilterByStatusCommand.Execute(allChip);

        _vm.FilteredEvents.Count.ShouldBe(2);
    }
}
