using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ExploreViewModelTests
{
    private readonly ExploreViewModel _vm;

    public ExploreViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApi = new EventsApiClient(client);
        var eventsService = new EventsService(eventsApi);
        var authMock = new Mock<IAuthService>();

        _vm = new ExploreViewModel(eventsService, authMock.Object);
    }

    [Fact]
    public void InitialState_ShouldHaveCategoriesAndDefaultSelection()
    {
        _vm.Categories.ShouldNotBeEmpty();
        _vm.Categories.Count.ShouldBe(15);
        _vm.Categories[0].Name.ShouldBe("Todos");
        _vm.Categories[0].IsSelected.ShouldBeTrue();
        _vm.SearchText.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsLoadingMore.ShouldBeFalse();
    }

    [Fact]
    public void SearchText_ShouldUpdateValue()
    {
        _vm.SearchText = "Show Rock";
        _vm.SearchText.ShouldBe("Show Rock");
    }
}
