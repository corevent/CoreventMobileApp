using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ResetPasswordViewModelTests
{
    private readonly Mock<IAuthService> _authMock;
    private readonly ResetPasswordViewModel _vm;

    public ResetPasswordViewModelTests()
    {
        _authMock = new Mock<IAuthService>();
        _vm = new ResetPasswordViewModel(_authMock.Object, new CoreventApp.Services.DialogService());
    }

    [Fact]
    public void InitialState_ShouldBeDefault()
    {
        _vm.Email.ShouldBeEmpty();
        _vm.Code.ShouldBeEmpty();
        _vm.NewPassword.ShouldBeEmpty();
        _vm.ConfirmPassword.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsError.ShouldBeFalse();
        _vm.ErrorMessage.ShouldBeEmpty();
    }

    [Fact]
    public async Task ResetAsync_ShouldShowError_WhenPasswordIsWeak()
    {
        _vm.Email = "teste@corevent.com";
        _vm.Code = "123456";
        _vm.NewPassword = "123";
        _vm.ConfirmPassword = "123";

        await _vm.ResetCommand.ExecuteAsync(null);

        _vm.IsError.ShouldBeTrue();
        _vm.ErrorMessage.ShouldContain("A senha deve ter 8+ caracteres");
    }

    [Fact]
    public async Task ResetAsync_ShouldShowError_WhenPasswordsDoNotMatch()
    {
        _vm.Email = "teste@corevent.com";
        _vm.Code = "123456";
        _vm.NewPassword = "Password@123";
        _vm.ConfirmPassword = "DifferentPassword@123";

        await _vm.ResetCommand.ExecuteAsync(null);

        _vm.IsError.ShouldBeTrue();
        _vm.ErrorMessage.ShouldBe("As senhas não conferem.");
    }
}
