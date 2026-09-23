using CommunityToolkit.Maui.Alerts;

namespace CoreventApp.Services;

/// <summary>
/// Centralizes user-facing dialogs. All methods are safe to call without a UI
/// context (e.g. unit tests): they no-op when no page is available instead of
/// throwing <see cref="NullReferenceException"/> on <c>Shell.Current</c>.
/// </summary>
public interface IDialogService
{
    Task ShowErrorAsync(string message, string title = "Erro", string cancel = "OK");
    Task ShowAlertAsync(string title, string message, string cancel = "OK");
    Task<bool> ConfirmAsync(string title, string message, string accept = "Sim", string cancel = "Cancelar");
    Task ShowToastAsync(string message);
}

public sealed class DialogService : IDialogService
{
    public Task ShowErrorAsync(string message, string title = "Erro", string cancel = "OK")
        => ShowAlertAsync(title, message, cancel);

    public async Task ShowAlertAsync(string title, string message, string cancel = "OK")
    {
        var page = Shell.Current?.CurrentPage;
        if (page is not null)
            await page.DisplayAlertAsync(title, message, cancel);
    }

    public async Task<bool> ConfirmAsync(string title, string message, string accept = "Sim", string cancel = "Cancelar")
    {
        var page = Shell.Current?.CurrentPage;
        if (page is not null)
            return await page.DisplayAlertAsync(title, message, accept, cancel);

        return false;
    }

    public async Task ShowToastAsync(string message)
    {
        if (Shell.Current?.CurrentPage is null)
            return;

        await Snackbar.Make(message).Show();
    }
}
