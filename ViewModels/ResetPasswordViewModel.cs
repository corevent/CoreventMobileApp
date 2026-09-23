using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(Email), "Email")]
[QueryProperty(nameof(Code), "Code")]
public partial class ResetPasswordViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly IDialogService _dialogs;

    public ResetPasswordViewModel(IAuthService authService, IDialogService dialogService)
    {
        _authService = authService;
        _dialogs = dialogService;
    }

    [ObservableProperty]
    public partial string Email { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Code { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string NewPassword { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string ConfirmPassword { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial string ErrorMessage { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsError { get; set; }

    partial void OnNewPasswordChanged(string value)
    {
        if (IsError) ClearError();
    }

    partial void OnConfirmPasswordChanged(string value)
    {
        if (IsError) ClearError();
    }

    [RelayCommand]
    private async Task ResetAsync()
    {
        if (IsLoading) return;

        if (!ValidationHelper.IsValidPassword(NewPassword))
        {
            ShowError("A senha deve ter 8+ caracteres, com maiúscula, minúscula, número e símbolo.");
            return;
        }

        if (NewPassword != ConfirmPassword)
        {
            ShowError("As senhas não conferem.");
            return;
        }

        IsLoading = true;
        ClearError();

        var success = await _authService.ResetPasswordAsync(Email, Code, NewPassword);

        IsLoading = false;

        if (success)
        {
            await _dialogs.ShowToastAsync("Senha redefinida com sucesso!");
            await Shell.Current.GoToAsync(AppRoutes.WelcomeLogin);
        }
        else
        {
            ShowError("Ocorreu um erro ao redefinir a senha. Tente novamente.");
        }
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    private void ShowError(string message)
    {
        IsError = true;
        ErrorMessage = message;
    }

    private void ClearError()
    {
        IsError = false;
        ErrorMessage = string.Empty;
    }
}
