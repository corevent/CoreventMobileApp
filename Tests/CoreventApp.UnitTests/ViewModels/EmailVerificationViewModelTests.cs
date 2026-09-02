using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class EmailVerificationViewModelTests
{
    private readonly Mock<IAuthService> _authMock;
    private readonly EmailVerificationViewModel _vm;

    public EmailVerificationViewModelTests()
    {
        _authMock = new Mock<IAuthService>();
        _vm = new EmailVerificationViewModel(_authMock.Object);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.Name.ShouldBeEmpty();
        _vm.Email.ShouldBeEmpty();
        _vm.DocumentType.ShouldBe("cpf");
        _vm.Mode.ShouldBe("register");
        _vm.Code.ShouldBeEmpty();
        _vm.IsError.ShouldBeFalse();
        _vm.ErrorMessage.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.CanResend.ShouldBeTrue();
    }

    [Fact]
    public async Task VerifyAsync_ShouldSetError_WhenCodeIsInvalid()
    {
        _vm.Code = "123";

        await _vm.VerifyCommand.ExecuteAsync(null);

        _vm.IsError.ShouldBeTrue();
        _vm.ErrorMessage.ShouldBe("Insira o código de 6 dígitos enviado por e-mail.");
    }

    [Fact]
    public void OnCodeChanged_ShouldClearErrorMessage()
    {
        _vm.IsError = true;
        _vm.ErrorMessage = "Erro anterior";

        _vm.Code = "999";

        _vm.IsError.ShouldBeFalse();
        _vm.ErrorMessage.ShouldBeEmpty();
    }
}
