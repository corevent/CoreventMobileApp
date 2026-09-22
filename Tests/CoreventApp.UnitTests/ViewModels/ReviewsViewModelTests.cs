using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ReviewsViewModelTests
{
    private readonly Mock<IEventRatingsApi> _ratingsApiMock;
    private readonly ReviewsViewModel _vm;

    public ReviewsViewModelTests()
    {
        _ratingsApiMock = new Mock<IEventRatingsApi>();
        _vm = new ReviewsViewModel(_ratingsApiMock.Object);
    }

    [Fact]
    public void InitialState_ShouldBeDefault()
    {
        _vm.Items.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsEmpty.ShouldBeFalse();
        _vm.IsRefreshing.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadItems_ShouldPopulateItemsAndSetIsEmpty()
    {
        var item = new MyRatingItemDto("evt_1", "Show SP", "https://img.com/1.jpg", 4.9, 5);

        _ratingsApiMock.Setup(a => a.GetMyRatingsAsync(1, 100))
            .ReturnsAsync(new MyRatingsListPageDto(
                new List<MyRatingItemDto> { item }, new PaginationMetaDto(1, 1, 1, 100)));

        await _vm.LoadItemsCommand.ExecuteAsync(null);

        _vm.Items.Count.ShouldBe(1);
        _vm.Items[0].EventTitle.ShouldBe("Show SP");
        _vm.IsEmpty.ShouldBeFalse();
        _vm.IsLoading.ShouldBeFalse();
    }
}
