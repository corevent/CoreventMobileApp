using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class ProfileViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly IDialogService _dialogs;

    public ProfileViewModel(IAuthService authService, IDialogService dialogService)
    {
        _authService = authService;
        _dialogs = dialogService;

        var cached = _authService.CurrentCachedUser;
        if (cached != null)
            ApplyUser(cached);
    }

    [ObservableProperty]
    public partial bool IsBusy { get; set; }

    [ObservableProperty]
    public partial string UserName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string UserEmail { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string UserAvatar { get; set; } = "profile_default_icon.png";

    [ObservableProperty]
    public partial bool IsAdult { get; set; } = true;

    [RelayCommand]
    public async Task LoadUserAsync()
    {
        if (IsBusy)
            return;

        try
        {
            IsBusy = true;
            var user = await _authService.GetCurrentUserAsync();
            if (user != null)
                ApplyUser(user);
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"ProfileViewModel.LoadUserAsync failed: {ex.Message}");
        }
        finally
        {
            IsBusy = false;
        }
    }

    private void ApplyUser(Models.User user)
    {
        UserName = user.Name;
        UserEmail = user.Email;

        if (!string.IsNullOrWhiteSpace(user.AvatarUrl))
            UserAvatar = user.AvatarUrl;

        IsAdult = user.IsAdult;
    }

    [RelayCommand]
    private async Task EditProfileAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.EditProfile));
    }

    [RelayCommand]
    private async Task PurchaseHistoryAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.PurchaseHistory));
    }

    [RelayCommand]
    private async Task FavoritesAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.Favorites));
    }

    [RelayCommand]
    private async Task ReviewsAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.Reviews));
    }

    [RelayCommand]
    private async Task SettingsAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.Settings));
    }

    [RelayCommand]
    private async Task LogoutAsync()
    {
        bool confirm = await _dialogs.ConfirmAsync("Aviso", "Deseja mesmo encerrar a sua sessão?");

        if (confirm)
        {
            await _authService.LogoutAsync();
            await Shell.Current.GoToAsync(AppRoutes.Welcome);
        }
    }

    [RelayCommand]
    private async Task PanelOrganizerAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.PanelOrganizer));
    }

    [RelayCommand]
    private async Task PanelCollaboratorAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.PanelCollaborator));
    }
}
