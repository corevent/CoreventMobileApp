using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class PanelCollaboratorViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly PanelCollaboratorViewModel _vm;

    public PanelCollaboratorViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApi = new EventsApiClient(client);
        var eventsService = new EventsService(eventsApi);
        var invitesApi = new StaffInvitesApiClient(client);

        _vm = new PanelCollaboratorViewModel(eventsService, invitesApi);
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
        var organizer = "{\"id\":\"o1\",\"name\":\"Org\",\"email\":\"o@t.com\",\"avatarUrl\":null}";
        var pastDate = DateTime.UtcNow.AddDays(-10).ToString("o");
        var futureDate = DateTime.UtcNow.AddDays(10).ToString("o");

        var eventsJson = $"{{\"data\":[{{\"id\":\"e_past\",\"title\":\"Passado\",\"maxParticipants\":100,\"cityName\":\"SP\",\"stateAcronym\":\"SP\",\"locationName\":\"Arena\",\"startDate\":\"{pastDate}\",\"endDate\":\"{pastDate}\",\"category\":\"music\",\"isAdultOnly\":false,\"status\":\"finished\",\"organizer\":{organizer},\"locationType\":\"in_person\",\"accessLevel\":\"checkin\"}},{{\"id\":\"e_future\",\"title\":\"Futuro\",\"maxParticipants\":200,\"cityName\":\"RJ\",\"stateAcronym\":\"RJ\",\"locationName\":\"Centro\",\"startDate\":\"{futureDate}\",\"endDate\":\"{futureDate}\",\"category\":\"tech\",\"isAdultOnly\":false,\"status\":\"opened\",\"organizer\":{organizer},\"locationType\":\"in_person\",\"accessLevel\":\"organizer\"}}],\"meta\":{{\"totalItems\":2,\"totalPages\":1,\"page\":1,\"limit\":100}}}}";

        var invitesJson = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":10}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/events/staff*")
            .Respond("application/json", eventsJson);

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/invitations/me*")
            .Respond("application/json", invitesJson);

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
