using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class ForgotPasswordViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly IDialogService _dialogs;

    public ForgotPasswordViewModel(IAuthService authService, IDialogService dialogService)
    {
        _authService = authService;
        _dialogs = dialogService;
    }

    [ObservableProperty]
    public partial string Email { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [RelayCommand]
    private async Task SendResetCodeAsync()
    {
        if (IsLoading) return;

        if (!ValidationHelper.IsValidEmail(Email))
        {
            await _dialogs.ShowAlertAsync("Aviso", "Informe seu e-mail para recuperar a senha.");
            return;
        }

        IsLoading = true;

        var resetCodeSent = await _authService.SendResetCodeAsync(Email);
        IsLoading = false;

        if (!resetCodeSent)
        {
            await _dialogs.ShowErrorAsync("Não foi possível enviar o código de recuperação. Tente novamente.");
            return;
        }

        await _dialogs.ShowToastAsync("E-mail enviado. Se o e-mail estiver cadastrado, enviaremos um código de verificação.");

        await Shell.Current.GoToAsync(nameof(Views.EmailVerification), new ShellNavigationQueryParameters
        {
            [nameof(EmailVerificationViewModel.Email)] = Email,
            [nameof(EmailVerificationViewModel.Mode)] = "reset"
        });
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }
}
