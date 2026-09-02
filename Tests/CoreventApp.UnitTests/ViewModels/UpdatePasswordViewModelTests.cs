using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class UpdatePasswordViewModelTests
{
    private readonly Mock<IAuthService> _authMock;
    private readonly UpdatePasswordViewModel _vm;

    public UpdatePasswordViewModelTests()
    {
        _authMock = new Mock<IAuthService>();
        _vm = new UpdatePasswordViewModel(_authMock.Object);
    }

    [Fact]
    public void InitialState_ShouldBeDefault()
    {
        _vm.CurrentPassword.ShouldBeEmpty();
        _vm.NewPassword.ShouldBeEmpty();
        _vm.ConfirmPassword.ShouldBeEmpty();
        _vm.IsBusy.ShouldBeFalse();
        _vm.IsNotBusy.ShouldBeTrue();
        _vm.ErrorMessage.ShouldBeEmpty();
    }

    [Fact]
    public async Task UpdatePassword_ShouldShowError_WhenFieldsAreEmpty()
    {
        await _vm.UpdatePasswordCommand.ExecuteAsync(null);

        _vm.ErrorMessage.ShouldBe("Preencha todos os campos.");
    }

    [Fact]
    public async Task UpdatePassword_ShouldShowError_WhenPasswordsDoNotMatch()
    {
        _vm.CurrentPassword = "CurrentPassword@123";
        _vm.NewPassword = "NewPassword@123";
        _vm.ConfirmPassword = "MismatchPassword@123";

        await _vm.UpdatePasswordCommand.ExecuteAsync(null);

        _vm.ErrorMessage.ShouldBe("As senhas não coincidem.");
    }

    [Fact]
    public async Task UpdatePassword_ShouldShowError_WhenNewPasswordIsWeak()
    {
        _vm.CurrentPassword = "CurrentPassword@123";
        _vm.NewPassword = "weak";
        _vm.ConfirmPassword = "weak";

        await _vm.UpdatePasswordCommand.ExecuteAsync(null);

        _vm.ErrorMessage.ShouldContain("A senha deve ter 8+ caracteres");
    }
}
