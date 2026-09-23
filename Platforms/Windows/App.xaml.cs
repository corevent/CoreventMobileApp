using Microsoft.UI.Windowing;
using Microsoft.Windows.AppLifecycle;
using Windows.ApplicationModel.Activation;

namespace CoreventApp.WinUI;

public partial class App : MauiWinUIApplication
{
    public App()
    {
        this.InitializeComponent();
    }

    protected override MauiApp CreateMauiApp() => MauiProgram.CreateMauiApp();

    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        var mainInstance = AppInstance.FindOrRegisterForKey("CoreventApp");
        var activationArgs = mainInstance.GetActivatedEventArgs();

        if (!mainInstance.IsCurrent)
        {
            mainInstance.RedirectActivationToAsync(activationArgs).GetAwaiter().GetResult();
            Microsoft.UI.Xaml.Application.Current.Exit();
            return;
        }

        mainInstance.Activated += OnActivated;

        base.OnLaunched(args);
        HandleActivation(activationArgs);
    }

    private void OnActivated(object? sender, AppActivationArguments args)
    {
        // Precisa rodar na UI thread
        MainThread.BeginInvokeOnMainThread(() => HandleActivation(args));
    }

    private void HandleActivation(AppActivationArguments args)
    {
        // Traz a janela existente para frente
        BringWindowToForeground();

        if (args.Kind != ExtendedActivationKind.Protocol) return;
        if (args.Data is not IProtocolActivatedEventArgs protocolArgs) return;

        _ = CoreventApp.App.HandleDeepLink(protocolArgs.Uri);
    }

    private void BringWindowToForeground()
    {
        var mauiApp = Microsoft.Maui.Controls.Application.Current;
        if (mauiApp?.Windows.Count > 0)
        {
            var nativeWindow = mauiApp.Windows[0].Handler?.PlatformView
                    as Microsoft.UI.Xaml.Window;

            if (nativeWindow is not null)
            {
                // Usando AppWindow para forçar o foco corretamente
                var appWindow = nativeWindow.AppWindow;
                appWindow?.Show();

                if (appWindow?.Presenter is OverlappedPresenter presenter)
                {
                    if (presenter.State == OverlappedPresenterState.Minimized)
                        presenter.Restore();

                    presenter.IsAlwaysOnTop = true;
                    presenter.IsAlwaysOnTop = false; // "pisca" para forçar foco
                }

                nativeWindow.Activate();
            }
        }
    }
}
