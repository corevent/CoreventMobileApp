using CoreventApp.Models;
using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class LoginViewModelTests
{
    private readonly Mock<IAuthService> _authServiceMock;
    private readonly LoginViewModel _viewModel;

    public LoginViewModelTests()
    {
        _authServiceMock = new Mock<IAuthService>();
        _viewModel = new LoginViewModel(_authServiceMock.Object, new CoreventApp.Services.DialogService());
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _viewModel.IsBusy.ShouldBeFalse();
        _viewModel.Form.ShouldNotBeNull();
        _viewModel.Form.Email.ShouldBeEmpty();
        _viewModel.Form.Password.ShouldBeEmpty();
    }

    [Fact]
    public void FormProperties_ShouldUpdateCorrectly()
    {
        _viewModel.Form.Email = "teste@corevent.com";
        _viewModel.Form.Password = "Senha@123";

        _viewModel.Form.Email.ShouldBe("teste@corevent.com");
        _viewModel.Form.Password.ShouldBe("Senha@123");
    }
}
