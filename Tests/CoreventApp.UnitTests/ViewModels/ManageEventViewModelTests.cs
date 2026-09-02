using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ManageEventViewModelTests
{
    private readonly ManageEventViewModel _vm;

    public ManageEventViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApi = new EventsApiClient(client);
        var eventsService = new EventsService(eventsApi);

        _vm = new ManageEventViewModel(eventsService);
    }

    [Fact]
    public void InitialState_ShouldBeDraft()
    {
        _vm.EventName.ShouldBeEmpty();
        _vm.Status.ShouldBe("draft");
        _vm.StatusDisplayText.ShouldBe("RASCUNHO");
        _vm.IsLoading.ShouldBeFalse();
        _vm.CanEdit.ShouldBeFalse();
        _vm.CanPublish.ShouldBeFalse();
        _vm.CanCancel.ShouldBeFalse();
        _vm.CanDelete.ShouldBeFalse();
    }

    [Fact]
    public void Properties_ShouldUpdateValues()
    {
        _vm.EventName = "Congresso de IA";
        _vm.EventDate = "15 Nov, 2026 - 09:00";
        _vm.Status = "opened";
        _vm.StatusDisplayText = "ATIVO";
        _vm.CanEdit = true;
        _vm.CanPublish = false;
        _vm.CanCancel = true;

        _vm.EventName.ShouldBe("Congresso de IA");
        _vm.EventDate.ShouldBe("15 Nov, 2026 - 09:00");
        _vm.Status.ShouldBe("opened");
        _vm.StatusDisplayText.ShouldBe("ATIVO");
        _vm.CanEdit.ShouldBeTrue();
        _vm.CanPublish.ShouldBeFalse();
        _vm.CanCancel.ShouldBeTrue();
    }
}
