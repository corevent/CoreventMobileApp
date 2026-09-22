using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class HomeViewModelTests
{
    private readonly Mock<IEventsApi> _eventsApiMock;
    private readonly Mock<IAuthService> _authMock;
    private readonly HomeViewModel _vm;

    public HomeViewModelTests()
    {
        _eventsApiMock = new Mock<IEventsApi>();
        _authMock = new Mock<IAuthService>();

        _vm = new HomeViewModel(_eventsApiMock.Object, _authMock.Object, new CoreventApp.Services.DialogService());
    }

    [Fact]
    public void InitialState_ShouldHaveEmptyEventsAndNotLoading()
    {
        _vm.IsLoading.ShouldBeFalse();
        _vm.HighlightedEvents.ShouldBeEmpty();
        _vm.OtherEvents.ShouldBeEmpty();
    }

    [Fact]
    public async Task LoadAsync_ShouldSeparateHighlightedAndOtherEvents()
    {
        var organizer = new OrganizerInfoDto("org_1", "Org", "org@test.com", null);
        var items = Enumerable.Range(1, 7).Select(i => new EventListItemDto(
            $"evt_{i}", $"Show {i}", 1000, "SP", "SP", "Arena",
            new DateTime(2026, 10, 10, 20, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 10, 10, 23, 0, 0, DateTimeKind.Utc),
            "music", false, "opened", organizer, "in_person", 4.5)).ToList();

        _eventsApiMock.Setup(a => a.GetAllAsync(1, 50, null, null, null, "opened", null, null, null))
            .ReturnsAsync(new EventListPageDto(items, new PaginationMetaDto(7, 1, 1, 50)));

        await _vm.LoadCommand.ExecuteAsync(null);

        _vm.HighlightedEvents.Count.ShouldBe(5);
        _vm.OtherEvents.Count.ShouldBe(2);
        _vm.IsLoading.ShouldBeFalse();
    }
}
