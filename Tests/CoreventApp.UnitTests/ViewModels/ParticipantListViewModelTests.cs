using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ParticipantListViewModelTests
{
    private readonly ParticipantListViewModel _vm;

    public ParticipantListViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new ParticipantsApiClient(client);
        var service = new ParticipantsService(api);

        _vm = new ParticipantListViewModel(service);
    }

    [Fact]
    public void InitialState_ShouldBeDefault()
    {
        _vm.EventId.ShouldBeEmpty();
        _vm.EventName.ShouldBeEmpty();
        _vm.Participants.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsEmpty.ShouldBeTrue();
    }

    [Fact]
    public void ParticipantSummary_ShouldMapProperties()
    {
        var summary = new ParticipantSummary
        {
            FullName = "Carlos Eduardo",
            Email = "carlos@teste.com",
            TicketsCount = 3
        };

        summary.FullName.ShouldBe("Carlos Eduardo");
        summary.Email.ShouldBe("carlos@teste.com");
        summary.TicketsCount.ShouldBe(3);
    }
}
