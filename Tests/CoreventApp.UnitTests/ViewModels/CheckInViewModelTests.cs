using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class CheckInViewModelTests
{
    private readonly CheckInViewModel _vm;

    public CheckInViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApi = new EventsApiClient(client);
        var eventsService = new EventsService(eventsApi);

        var checkInApi = new CheckInApiClient(client);
        var checkInService = new CheckInService(checkInApi);

        _vm = new CheckInViewModel(eventsService, checkInService);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.EventName.ShouldBeEmpty();
        _vm.CheckInCount.ShouldBe("0/0");
        _vm.ResultMessage.ShouldBeEmpty();
        _vm.IsResultVisible.ShouldBeFalse();
        _vm.IsResultSuccess.ShouldBeFalse();
        _vm.IsScannerBlocked.ShouldBeTrue();
        _vm.IsScanning.ShouldBeFalse();
    }

    [Fact]
    public void DismissResult_ShouldResetResultStateAndEnableScanning()
    {
        _vm.IsResultVisible = true;
        _vm.ResultMessage = "Sucesso!";
        _vm.IsScanning = false;

        _vm.DismissResultCommand.Execute(null);

        _vm.IsResultVisible.ShouldBeFalse();
        _vm.ResultMessage.ShouldBeEmpty();
        _vm.IsScanning.ShouldBeTrue();
    }
}
