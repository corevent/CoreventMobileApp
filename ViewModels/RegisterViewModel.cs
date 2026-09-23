using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class RegisterViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly IDialogService _dialogs;
    private const int TotalSteps = 4;

    public RegisterViewModel(IAuthService authService, IDialogService dialogService)
    {
        _authService = authService;
        _dialogs = dialogService;
    }

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

    [ObservableProperty]
    public partial int CurrentStep { get; set; } = 1;

    [ObservableProperty]
    public partial double Progress { get; set; } = 0.25;

    [ObservableProperty]
    public partial string StepTitle { get; set; } = "Conte-nos sobre você";

    [ObservableProperty]
    public partial string StepDescription { get; set; } = "Vamos começar com o básico para criar seu perfil.";

    [ObservableProperty]
    public partial string ButtonNextText { get; set; } = "Próximo";

    [ObservableProperty]
    public partial RegisterRequest Form { get; set; } = new();

    [ObservableProperty]
    public partial DateTime DataNascimentoMax { get; set; } = DateTime.Today;

    [RelayCommand]
    private async Task NextAsync()
    {
        if (IsBusy) return;

        if (CurrentStep < TotalSteps)
        {
            if (!await ValidateStepAsync(CurrentStep)) return;
            CurrentStep++;
            UpdateUI();
        }
        else
        {
            if (!await ValidateAllAsync()) return;

            IsBusy = true;

            var verificationEmailSent = await _authService.SendVerificationEmailAsync(Form.Email);
            IsBusy = false;

            if (!verificationEmailSent)
            {
                await _dialogs.ShowErrorAsync("Não foi possível enviar o código de verificação. Tente novamente.");
                return;
            }

            var document = Form.AccountType == "pj"
              ? System.Text.RegularExpressions.Regex.Replace(Form.Cnpj, @"\D", "")
              : System.Text.RegularExpressions.Regex.Replace(Form.Cpf, @"\D", "");
            var documentType = Form.AccountType == "pj" ? "cnpj" : "cpf";

            await Shell.Current.GoToAsync(
              $"EmailVerification?Name={Uri.EscapeDataString(Form.Nome)}" +
              $"&Email={Uri.EscapeDataString(Form.Email)}" +
              $"&Password={Uri.EscapeDataString(Form.Senha)}" +
              $"&Document={Uri.EscapeDataString(document)}" +
              $"&DocumentType={Uri.EscapeDataString(documentType)}" +
              $"&BirthDate={Uri.EscapeDataString(Form.DataNascimento.ToString("yyyy-MM-dd"))}");
        }
    }

    [RelayCommand]
    private async Task SelectAccountTypeAsync(string type)
    {
        Form.AccountType = type;
        Form.Cpf = string.Empty;
        Form.Cnpj = string.Empty;
        await NextAsync();
    }

    [RelayCommand]
    private async Task HeaderBackAsync()
    {
        if (CurrentStep > 1)
        {
            CurrentStep--;
            UpdateUI();
            return;
        }

        await Shell.Current.GoToAsync("..");
    }

    private async Task<bool> ValidateStepAsync(int step)
    {
        return step switch
        {
            1 => !string.IsNullOrWhiteSpace(Form.Nome) && Form.Nome.Trim().Length >= 3,
            2 => true,
            3 => await ValidateDocumentAsync(),
            4 => await ValidateCredentialsAsync(),
            _ => true
        };
    }

    private async Task<bool> ValidateDocumentAsync()
    {
        var doc = Form.AccountType == "pj" ? Form.Cnpj : Form.Cpf;
        if (Form.AccountType == "pj")
        {
            if (!ValidationHelper.IsValidCnpj(doc))
            {
                await _dialogs.ShowErrorAsync("CNPJ inválido. Informe um CNPJ com 14 dígitos.");
                return false;
            }
        }
        else
        {
            if (!ValidationHelper.IsValidCpf(doc))
            {
                await _dialogs.ShowErrorAsync("CPF inválido. Informe um CPF com 11 dígitos.");
                return false;
            }
        }
        return true;
    }

    private async Task<bool> ValidateCredentialsAsync()
    {
        if (!ValidationHelper.IsValidEmail(Form.Email))
        {
            await _dialogs.ShowErrorAsync("Informe um e-mail válido.");
            return false;
        }
        if (!ValidationHelper.IsValidPassword(Form.Senha))
        {
            await _dialogs.ShowErrorAsync("A senha deve ter 8+ caracteres, com maiúscula, minúscula, número e símbolo.");
            return false;
        }
        if (Form.Senha != Form.ConfirmarSenha)
        {
            await _dialogs.ShowErrorAsync("As senhas não conferem.");
            return false;
        }
        return true;
    }

    private async Task<bool> ValidateAllAsync()
    {
        if (string.IsNullOrWhiteSpace(Form.Nome) || Form.Nome.Trim().Length < 3)
        {
            await _dialogs.ShowErrorAsync("O nome deve ter pelo menos 3 caracteres.");
            return false;
        }
        if (!await ValidateDocumentAsync())
            return false;
        return await ValidateCredentialsAsync();
    }

    private void UpdateUI()
    {
        Progress = (double)CurrentStep / TotalSteps;
        ButtonNextText = CurrentStep == TotalSteps ? "Finalizar" : "Próximo";

        StepTitle = CurrentStep switch
        {
            1 => "Conte-nos sobre você",
            2 => "Pessoa ou Empresa?",
            3 => "Seu documento",
            4 => "Credenciais de acesso",
            _ => string.Empty
        };

        StepDescription = CurrentStep switch
        {
            1 => "Vamos começar com o básico para criar seu perfil.",
            2 => "Você é pessoa física ou jurídica?",
            3 => "Informe o documento da sua conta.",
            4 => "Informe seu e-mail e crie uma senha para entrar no app.",
            _ => string.Empty
        };
    }
}

public partial class RegisterRequest : ObservableObject
{
    [ObservableProperty]
    public partial string Nome { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Email { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Cpf { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Cnpj { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Senha { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string ConfirmarSenha { get; set; } = string.Empty;

    [ObservableProperty]
    public partial DateTime DataNascimento { get; set; } = new(2000, 1, 1);

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsPessoaFisica))]
    [NotifyPropertyChangedFor(nameof(IsPessoaJuridica))]
    public partial string AccountType { get; set; } = "pf";

    public bool IsPessoaFisica => AccountType == "pf";
    public bool IsPessoaJuridica => AccountType == "pj";
}
