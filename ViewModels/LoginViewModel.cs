using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Services;
using CoreventApp.Views;

namespace CoreventApp.ViewModels;

public partial class LoginViewModel : ObservableObject
{
  private readonly IAuthService _authService;
  private readonly IDialogService _dialogs;

  public LoginViewModel(IAuthService authService, IDialogService dialogService)
  {
    _authService = authService;
    _dialogs = dialogService;
  }

  [ObservableProperty]
  public partial bool IsBusy { get; set; }

  [ObservableProperty]
  public partial LoginRequest Form { get; set; } = new();

  [RelayCommand]
  private async Task LoginAsync()
  {
    if (IsBusy) return;

    if (!ValidationHelper.IsValidEmail(Form.Email) || string.IsNullOrWhiteSpace(Form.Password))
    {
      await _dialogs.ShowErrorAsync("Preencha todos os campos.");
      return;
    }

    IsBusy = true;

    var user = await _authService.LoginAsync(Form.Email, Form.Password);

    IsBusy = false;

    if (user != null)
    {
      await Shell.Current.GoToAsync("//main/home");
    }
    else
    {
      await _dialogs.ShowErrorAsync("E-mail ou senha incorretos.");
    }
  }

  [RelayCommand]
  private async Task GoToRegisterAsync()
  {
    await Shell.Current.GoToAsync(nameof(Register));
  }

  [RelayCommand]
  private async Task MissingPasswordAsync()
  {
    await Shell.Current.GoToAsync(nameof(ForgotPassword));
  }
}

public partial class LoginRequest : ObservableObject
{
  [ObservableProperty]
  public partial string Email { get; set; } = string.Empty;

  [ObservableProperty]
  public partial string Password { get; set; } = string.Empty;
}