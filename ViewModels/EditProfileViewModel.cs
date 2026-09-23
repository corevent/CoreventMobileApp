using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Services;
using Microsoft.Maui.ApplicationModel;

namespace CoreventApp.ViewModels;

public partial class EditProfileViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly StorageService _storageService;
    private readonly IDialogService _dialogs;
    private Stream? _avatarStream;
    private string? _avatarContentType;

    public EditProfileViewModel(IAuthService authService, StorageService storageService, IDialogService dialogService)
    {
        _authService = authService;
        _storageService = storageService;
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
    public partial string UserPhone { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string UserAvatar { get; set; } = string.Empty;

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
            await _dialogs.ShowErrorAsync($"EditProfileViewModel.LoadUserAsync failed: {ex.Message}");
        }
        finally
        {
            IsBusy = false;
        }
    }

    private void ApplyUser(Models.User user)
    {
        UserName = user.Name;
        UserPhone = user.PhoneNumber ?? string.Empty;
        UserAvatar = user.AvatarUrl;
    }

    [RelayCommand]
    private async Task PickAvatar()
    {
        if (!await EnsurePhotoPermissionAsync()) return;

        try
        {
            var photos = await MediaPicker.Default.PickPhotosAsync(new MediaPickerOptions
            {
                SelectionLimit = 1,
                Title = "Selecionar foto"
            });

            var photo = photos.FirstOrDefault();

            if (photo is null) return;

            var contentType = photo.ContentType?.ToLowerInvariant() ?? string.Empty;
            if (contentType != "image/jpeg" && contentType != "image/png" && contentType != "image/webp" && contentType != "image/jpg")
            {
                await _dialogs.ShowAlertAsync("Formato inválido", "Selecione uma imagem nos formatos JPEG, PNG ou WebP.");
                return;
            }

            _avatarStream?.Dispose();
            _avatarStream = await photo.OpenReadAsync();
            _avatarContentType = contentType;

            if (_avatarStream.CanSeek)
                _avatarStream.Position = 0;
            UserAvatar = photo.FullPath;
        }
        catch (PermissionException)
        {
            await _dialogs.ShowErrorAsync("Permita o acesso às fotos para escolher uma imagem.");
        }
    }

    private async Task<bool> EnsurePhotoPermissionAsync()
    {
        var status = await Permissions.CheckStatusAsync<Permissions.StorageRead>();
        if (status != PermissionStatus.Granted)
            status = await Permissions.RequestAsync<Permissions.StorageRead>();

        if (status == PermissionStatus.Granted) return true;

        await _dialogs.ShowErrorAsync("Permita o acesso às fotos para escolher uma imagem.");
        return false;
    }

    [RelayCommand]
    private async Task Save()
    {
        if (string.IsNullOrWhiteSpace(UserName) || UserName.Trim().Length < 3)
        {
            await _dialogs.ShowErrorAsync("O nome deve ter pelo menos 3 caracteres.");
            return;
        }

        if (!string.IsNullOrWhiteSpace(UserPhone) && !ValidationHelper.IsValidPhone(UserPhone))
        {
            await _dialogs.ShowErrorAsync("Telefone inválido. Use o formato (11) 91234-5678.");
            return;
        }

        string? avatarUrl = null;

        if (_avatarStream is not null)
        {
            IsBusy = true;
            _avatarStream.Position = 0;
            avatarUrl = await _storageService.UploadAvatarAsync(_avatarStream, _avatarContentType!);
            IsBusy = false;

            if (avatarUrl is null)
            {
                await _dialogs.ShowErrorAsync("Não foi possível fazer upload da imagem. Verifique sua conexão.");
                return;
            }
        }

        var phone = string.IsNullOrWhiteSpace(UserPhone) ? null : UserPhone;
        var success = await _authService.UpdateProfileAsync(UserName.Trim(), phone);
        if (success)
        {
            await Shell.Current.GoToAsync("..");
        }
    }

    [RelayCommand]
    private async Task GoBack()
    {
        _avatarStream?.Dispose();
        _avatarStream = null;
        await Shell.Current.GoToAsync("..");
    }
}
