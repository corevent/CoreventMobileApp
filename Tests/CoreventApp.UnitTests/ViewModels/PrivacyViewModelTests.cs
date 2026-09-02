using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class PrivacyViewModelTests
{
    [Fact]
    public void Constructor_ShouldInitializeCorrectly()
    {
        var authMock = new Mock<IAuthService>();
        var vm = new PrivacyViewModel(authMock.Object);

        vm.ShouldNotBeNull();
    }
}
