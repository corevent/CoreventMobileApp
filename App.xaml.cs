using CoreventApp.Services;
using CoreventApp.Views;

namespace CoreventApp;

public partial class App : Application
{
    private readonly AppShell appShell;
    private readonly IAuthService authService;

    // Sinaliza quando o Shell estiver pronto para receber navegação
    private static readonly TaskCompletionSource _shellReady = new();
    private static Uri? _pendingDeepLink;

    public App(AppShell appShell, IAuthService authService)
    {
        InitializeComponent();
        this.appShell = appShell;
        this.authService = authService;
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        var loadingPage = new LoadingPage();
        var window = new Window(loadingPage) { Title = "Corevent" };
        _ = InitializeAsync(window);
        return window;
    }

    private async Task InitializeAsync(Window window)
    {
        var user = await authService.GetCurrentUserAsync();

        await MainThread.InvokeOnMainThreadAsync(async () =>
        {
            window.Page = appShell;

            if (user != null)
                await Shell.Current.GoToAsync(AppRoutes.Main);

            _shellReady.TrySetResult();

            if (_pendingDeepLink is not null)
            {
                await NavigateToDeepLink(_pendingDeepLink);
                _pendingDeepLink = null;
            }
        });
    }

    public static async Task HandleDeepLink(Uri uri)
    {
        if (uri.Scheme != "corevent") return;

        var shellReadyTask = _shellReady.Task;
        var completed = await Task.WhenAny(shellReadyTask, Task.Delay(TimeSpan.FromSeconds(5)));

        if (completed != shellReadyTask)
        {
            _pendingDeepLink = uri;
            return;
        }

        await MainThread.InvokeOnMainThreadAsync(() => NavigateToDeepLink(uri));
    }

    private static async Task NavigateToDeepLink(Uri uri)
    {
        switch (uri.Host)
        {
            case "orders":
                await Shell.Current.GoToAsync(AppRoutes.Tickets);
                break;
            case "invites":
                await Shell.Current.GoToAsync(nameof(UserInvitations));
                break;
        }
    }

    protected override void OnAppLinkRequestReceived(Uri uri)
    {
        base.OnAppLinkRequestReceived(uri);
        _ = HandleDeepLink(uri);
    }
}
