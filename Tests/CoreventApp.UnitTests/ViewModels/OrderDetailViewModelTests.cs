using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class OrderDetailViewModelTests
{
    private readonly OrderDetailViewModel _vm;

    public OrderDetailViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var apiMock = new Mock<IOrdersApi>();

        _vm = new OrderDetailViewModel(apiMock.Object);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.OrderId.ShouldBeEmpty();
        _vm.Order.ShouldBeNull();
        _vm.Tickets.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Theory]
    [InlineData("paid", "CONCLUÍDO")]
    [InlineData("pending", "PENDENTE")]
    [InlineData("cancelled", "CANCELADO")]
    [InlineData("checked_in", "FINALIZADO")]
    [InlineData("other_status", "OTHER_STATUS")]
    public void StatusText_ShouldTranslateStatusProperly(string input, string expected)
    {
        OrderDetailViewModel.StatusText(input).ShouldBe(expected);
    }
}
