using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class UpdatePasswordViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly IDialogService _dialogs;

    [ObservableProperty]
    public partial string CurrentPassword { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string NewPassword { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string ConfirmPassword { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

    [ObservableProperty]
    public partial string ErrorMessage { get; set; } = string.Empty;

    public bool IsNotBusy => !IsBusy;

    public UpdatePasswordViewModel(IAuthService authService, IDialogService dialogService)
    {
        _authService = authService;
        _dialogs = dialogService;
    }

    [RelayCommand]
    private async Task GoBack() => await Shell.Current.GoToAsync("..");

    [RelayCommand]
    private async Task UpdatePassword()
    {
        if (string.IsNullOrWhiteSpace(CurrentPassword) || string.IsNullOrWhiteSpace(NewPassword))
        {
            ErrorMessage = "Preencha todos os campos.";
            return;
        }

        if (NewPassword != ConfirmPassword)
        {
            ErrorMessage = "As senhas não coincidem.";
            return;
        }

        if (!ValidationHelper.IsValidPassword(NewPassword))
        {
            ErrorMessage = "A senha deve ter 8+ caracteres, maiúscula, minúscula, número e símbolo.";
            return;
        }

        IsBusy = true;
        OnPropertyChanged(nameof(IsNotBusy));
        ErrorMessage = string.Empty;

        try
        {
            bool success = await _authService.UpdatePasswordAsync(CurrentPassword, NewPassword);
            if (success)
            {
                await _dialogs.ShowToastAsync("Senha atualizada com sucesso!");
                await GoBack();
            }
            else
            {
                ErrorMessage = "Senha atual incorreta.";
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"UpdatePassword failed: {ex.Message}");
            await _dialogs.ShowErrorAsync("Ocorreu um erro ao atualizar a senha.");
        }
        finally
        {
            IsBusy = false;
            OnPropertyChanged(nameof(IsNotBusy));
        }
    }

}
