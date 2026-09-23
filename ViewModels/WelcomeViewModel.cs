using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Views;

namespace CoreventApp.ViewModels;

public partial class WelcomeViewModel : ObservableObject
{
    [RelayCommand]
    private async Task RegisterAsync()
    {
        await Shell.Current.GoToAsync(nameof(Register));
    }

    [RelayCommand]
    private async Task LoginAsync()
    {
        await Shell.Current.GoToAsync(nameof(Login));
    }
}
