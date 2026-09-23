using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.OS;

namespace CoreventApp;

[Activity(
    Name = "com.corevent.coreventapp.MainActivity",
    Theme = "@style/Maui.SplashTheme",
    MainLauncher = true,
    LaunchMode = LaunchMode.SingleTask,
    ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation | ConfigChanges.UiMode | ConfigChanges.ScreenLayout | ConfigChanges.SmallestScreenSize | ConfigChanges.Density)]
public class MainActivity : MauiAppCompatActivity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);
        HandleIntent(Intent);
    }

    protected override void OnNewIntent(Intent? intent)
    {
        base.OnNewIntent(intent);
        HandleIntent(intent);
    }

    private static void HandleIntent(Intent? intent)
    {
        if (intent?.Action != Intent.ActionView) return;
        if (string.IsNullOrEmpty(intent.DataString)) return;
        if (Uri.TryCreate(intent.DataString, UriKind.Absolute, out var uri))
            _ = App.HandleDeepLink(uri);
    }
}
