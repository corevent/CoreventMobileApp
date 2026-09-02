using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ForgotPasswordViewModelTests
{
    private readonly Mock<IAuthService> _authMock;
    private readonly ForgotPasswordViewModel _vm;

    public ForgotPasswordViewModelTests()
    {
        _authMock = new Mock<IAuthService>();
        _vm = new ForgotPasswordViewModel(_authMock.Object);
    }

    [Fact]
    public void InitialState_ShouldHaveEmptyEmailAndNotLoading()
    {
        _vm.Email.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public void EmailProperty_ShouldUpdateValue()
    {
        _vm.Email = "usuario@teste.com";
        _vm.Email.ShouldBe("usuario@teste.com");
    }
}
