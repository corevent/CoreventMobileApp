using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class TicketsViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly TicketsService _ticketsService;
    private readonly TicketsViewModel _vm;

    public TicketsViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new TicketsApiClient(client);
        _ticketsService = new TicketsService(api);

        _vm = new TicketsViewModel(_ticketsService);
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
        var json = "{\"data\":[{\"id\":\"t1\",\"status\":\"paid\",\"ticketTypeId\":\"tt1\",\"eventId\":\"e1\",\"userId\":\"u1\",\"qrToken\":\"qr1\",\"user\":{\"id\":\"u1\",\"name\":\"Lucas\"},\"ticketType\":{\"id\":\"tt1\",\"name\":\"Pista\",\"price\":50.0},\"event\":{\"id\":\"e1\",\"title\":\"Rock Fest\",\"bannerUrl\":\"https://img.com/1.png\",\"startDate\":\"2026-10-10T20:00:00.000Z\",\"endDate\":\"2026-10-10T23:00:00.000Z\"},\"order\":{\"id\":\"o1\"}},{\"id\":\"t2\",\"status\":\"used\",\"ticketTypeId\":\"tt2\",\"eventId\":\"e2\",\"userId\":\"u1\",\"qrToken\":\"qr2\",\"user\":{\"id\":\"u1\",\"name\":\"Lucas\"},\"ticketType\":{\"id\":\"tt2\",\"name\":\"Camarote\",\"price\":100.0},\"event\":{\"id\":\"e2\",\"title\":\"Jazz Night\",\"bannerUrl\":\"https://img.com/2.png\",\"startDate\":\"2026-08-10T20:00:00.000Z\",\"endDate\":\"2026-08-10T23:00:00.000Z\"},\"order\":{\"id\":\"o2\"}}],\"meta\":{\"totalItems\":2,\"totalPages\":1,\"page\":1,\"limit\":100}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/tickets*")
            .Respond("application/json", json);

        await _vm.LoadTicketsCommand.ExecuteAsync(null);

        _vm.ProximosTickets.Count.ShouldBe(1);
        _vm.ProximosTickets[0].Id.ShouldBe("t1");
        _vm.PassadosTickets.Count.ShouldBe(1);
        _vm.PassadosTickets[0].Id.ShouldBe("t2");
        _vm.IsEmptyProximos.ShouldBeFalse();
        _vm.IsEmptyPassados.ShouldBeFalse();
    }
}
