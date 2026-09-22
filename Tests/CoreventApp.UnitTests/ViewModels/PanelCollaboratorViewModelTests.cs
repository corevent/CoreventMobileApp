using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class PanelCollaboratorViewModelTests
{
    private readonly Mock<IEventsApi> _eventsApiMock;
    private readonly PanelCollaboratorViewModel _vm;

    public PanelCollaboratorViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        _eventsApiMock = new Mock<IEventsApi>();
        var invitesApi = new StaffInvitesApiClient(client);

        _vm = new PanelCollaboratorViewModel(_eventsApiMock.Object, invitesApi);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultTabVisibility()
    {
        _vm.IsAgendaVisible.ShouldBeTrue();
        _vm.IsHistoricoVisible.ShouldBeFalse();
        _vm.EventsToday.ShouldBeEmpty();
        _vm.UpcomingEvents.ShouldBeEmpty();
        _vm.PastEvents.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.HasPendingInvites.ShouldBeFalse();
    }

    [Fact]
    public void SelectHistoricoAndAgenda_ShouldToggleVisibility()
    {
        _vm.SelectHistoricoCommand.Execute(null);
        _vm.IsAgendaVisible.ShouldBeFalse();
        _vm.IsHistoricoVisible.ShouldBeTrue();

        _vm.SelectAgendaCommand.Execute(null);
        _vm.IsAgendaVisible.ShouldBeTrue();
        _vm.IsHistoricoVisible.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadAsync_ShouldCategorizeEventsByDate()
    {
        var organizer = new OrganizerInfoDto("o1", "Org", "o@t.com", null);
        var past = new StaffEventListItemDto("e_past", "Passado", 100, "SP", "SP", "Arena",
            DateTime.UtcNow.AddDays(-10), DateTime.UtcNow.AddDays(-10), "music", false, "finished", organizer, "checkin");
        var future = new StaffEventListItemDto("e_future", "Futuro", 200, "RJ", "RJ", "Centro",
            DateTime.UtcNow.AddDays(10), DateTime.UtcNow.AddDays(10), "tech", false, "opened", organizer, "organizer");
        var empty = new StaffEventListPageDto(new List<StaffEventListItemDto>(), new PaginationMetaDto(0, 0, 1, 100));

        _eventsApiMock.Setup(a => a.GetMyStaffEventsAsync(1, 100, "opened", null, null, null, null, null, null))
            .ReturnsAsync(new StaffEventListPageDto(new List<StaffEventListItemDto> { future }, new PaginationMetaDto(1, 1, 1, 100)));
        _eventsApiMock.Setup(a => a.GetMyStaffEventsAsync(1, 100, "going", null, null, null, null, null, null))
            .ReturnsAsync(empty);
        _eventsApiMock.Setup(a => a.GetMyStaffEventsAsync(1, 100, "finished", null, null, null, null, null, null))
            .ReturnsAsync(new StaffEventListPageDto(new List<StaffEventListItemDto> { past }, new PaginationMetaDto(1, 1, 1, 100)));

        await _vm.LoadCommand.ExecuteAsync(null);

        _vm.PastEvents.Count.ShouldBe(1);
        _vm.PastEvents[0].Title.ShouldBe("Passado");
        _vm.PastEvents[0].Role.ShouldBe("CREDENCIAMENTO");

        _vm.UpcomingEvents.Count.ShouldBe(1);
        _vm.UpcomingEvents[0].Title.ShouldBe("Futuro");
        _vm.UpcomingEvents[0].Role.ShouldBe("ORGANIZAÇÃO");

        _vm.HasUpcomingEvents.ShouldBeTrue();
        _vm.HasPastEvents.ShouldBeTrue();
    }
}
