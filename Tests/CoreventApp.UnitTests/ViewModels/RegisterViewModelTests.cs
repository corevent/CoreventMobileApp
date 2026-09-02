using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class RegisterViewModelTests
{
    private readonly Mock<IAuthService> _authMock;
    private readonly RegisterViewModel _vm;

    public RegisterViewModelTests()
    {
        _authMock = new Mock<IAuthService>();
        _vm = new RegisterViewModel(_authMock.Object);
    }

    [Fact]
    public void InitialState_ShouldBeOnStep1WithPfDefault()
    {
        _vm.CurrentStep.ShouldBe(1);
        _vm.Progress.ShouldBe(0.25);
        _vm.StepTitle.ShouldBe("Conte-nos sobre você");
        _vm.ButtonNextText.ShouldBe("Próximo");
        _vm.Form.AccountType.ShouldBe("pf");
        _vm.Form.IsPessoaFisica.ShouldBeTrue();
        _vm.Form.IsPessoaJuridica.ShouldBeFalse();
    }

    [Fact]
    public async Task NextAsync_ShouldAdvanceToStep2_WhenNameIsValid()
    {
        _vm.Form.Nome = "Lucas Silva";

        await _vm.NextCommand.ExecuteAsync(null);

        _vm.CurrentStep.ShouldBe(2);
        _vm.Progress.ShouldBe(0.5);
        _vm.StepTitle.ShouldBe("Pessoa ou Empresa?");
    }

    [Fact]
    public async Task NextAsync_ShouldNotAdvance_WhenNameIsTooShort()
    {
        _vm.Form.Nome = "Lu";

        await _vm.NextCommand.ExecuteAsync(null);

        _vm.CurrentStep.ShouldBe(1);
    }

    [Fact]
    public async Task SelectAccountTypeAsync_ShouldUpdateTypeAndAdvance()
    {
        _vm.Form.Nome = "Lucas Silva";
        await _vm.NextCommand.ExecuteAsync(null);

        await _vm.SelectAccountTypeCommand.ExecuteAsync("pj");

        _vm.Form.AccountType.ShouldBe("pj");
        _vm.Form.IsPessoaJuridica.ShouldBeTrue();
        _vm.Form.IsPessoaFisica.ShouldBeFalse();
        _vm.CurrentStep.ShouldBe(3);
    }

    [Fact]
    public async Task HeaderBackAsync_ShouldGoToPreviousStep()
    {
        _vm.Form.Nome = "Lucas Silva";
        await _vm.NextCommand.ExecuteAsync(null);
        _vm.CurrentStep.ShouldBe(2);

        await _vm.HeaderBackCommand.ExecuteAsync(null);
        _vm.CurrentStep.ShouldBe(1);
        _vm.Progress.ShouldBe(0.25);
    }

    [Fact]
    public void RegisterRequest_Properties_ShouldSetValuesCorrectly()
    {
        var form = new RegisterRequest
        {
            Nome = "Empresa Top",
            Email = "contato@empresa.com",
            Cnpj = "11.222.333/0001-81",
            Cpf = "123.456.789-00",
            Senha = "Password@123",
            ConfirmarSenha = "Password@123",
            DataNascimento = new DateTime(1990, 5, 20),
            AccountType = "pj"
        };

        form.Nome.ShouldBe("Empresa Top");
        form.Email.ShouldBe("contato@empresa.com");
        form.Cnpj.ShouldBe("11.222.333/0001-81");
        form.Cpf.ShouldBe("123.456.789-00");
        form.Senha.ShouldBe("Password@123");
        form.ConfirmarSenha.ShouldBe("Password@123");
        form.DataNascimento.ShouldBe(new DateTime(1990, 5, 20));
        form.IsPessoaJuridica.ShouldBeTrue();
    }
}
