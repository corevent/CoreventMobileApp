using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.Models.Dtos;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ExploreViewModelTests
{
    private readonly ExploreViewModel _vm;

    public ExploreViewModelTests()
    {
        var eventsApiMock = new Mock<IEventsApi>();
        var authMock = new Mock<IAuthService>();

        _vm = new ExploreViewModel(eventsApiMock.Object, authMock.Object, new CoreventApp.Services.DialogService());
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

    [Fact]
    public async Task LoadMore_ShouldWaitForInitialSearch_AndStopAtLastPage()
    {
        var pendingPage = new TaskCompletionSource<EventListPageDto>(TaskCreationOptions.RunContinuationsAsynchronously);
        var eventsApi = new Mock<IEventsApi>();
        eventsApi.Setup(api => api.GetAllAsync(1, 10, null, null, null, "opened", null, null, null, It.IsAny<CancellationToken>()))
            .Returns(pendingPage.Task);
        var vm = new ExploreViewModel(eventsApi.Object, new Mock<IAuthService>().Object, new DialogService());

        var search = vm.SearchCommand.ExecuteAsync(null);
        await vm.LoadMoreCommand.ExecuteAsync(null);
        eventsApi.Verify(api => api.GetAllAsync(2, It.IsAny<int>(), It.IsAny<string?>(), It.IsAny<string?>(),
            It.IsAny<DateTime?>(), It.IsAny<string?>(), It.IsAny<bool?>(), It.IsAny<int?>(), It.IsAny<int?>(),
            It.IsAny<CancellationToken>()), Times.Never);

        pendingPage.SetResult(new EventListPageDto(new List<EventListItemDto>(), new PaginationMetaDto(0, 1, 1, 10)));
        await search;
        await vm.LoadMoreCommand.ExecuteAsync(null);

        eventsApi.Verify(api => api.GetAllAsync(It.IsAny<int>(), It.IsAny<int>(), It.IsAny<string?>(),
            It.IsAny<string?>(), It.IsAny<DateTime?>(), It.IsAny<string?>(), It.IsAny<bool?>(),
            It.IsAny<int?>(), It.IsAny<int?>(), It.IsAny<CancellationToken>()), Times.Once);
    }
}
