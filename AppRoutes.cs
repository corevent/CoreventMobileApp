namespace CoreventApp;

/// <summary>Absolute routes declared in AppShell.xaml.</summary>
public static class AppRoutes
{
    public const string Welcome = "//welcome";
    public const string Main = "//main";
    public const string Home = "//main/home";
    public const string Tickets = "//main/tickets";
    public static string WelcomeLogin => $"{Welcome}/{nameof(Views.Login)}";
}
