using CoreventApp.Views;

namespace CoreventApp;

public partial class AppShell : Shell
{
    public AppShell()
    {
        InitializeComponent();

        Routing.RegisterRoute(nameof(Login), typeof(Login));
        Routing.RegisterRoute(nameof(Register), typeof(Register));
        Routing.RegisterRoute(nameof(UpdatePassword), typeof(UpdatePassword));
        Routing.RegisterRoute(nameof(Privacy), typeof(Privacy));
        Routing.RegisterRoute(nameof(EditProfile), typeof(EditProfile));
        Routing.RegisterRoute(nameof(PurchaseHistory), typeof(PurchaseHistory));
        Routing.RegisterRoute(nameof(Favorites), typeof(Favorites));
        Routing.RegisterRoute(nameof(Reviews), typeof(Reviews));
        Routing.RegisterRoute(nameof(Settings), typeof(Settings));
        Routing.RegisterRoute(nameof(PanelOrganizer), typeof(PanelOrganizer));
        Routing.RegisterRoute(nameof(TransferSettings), typeof(TransferSettings));
        Routing.RegisterRoute(nameof(AddBankAccount), typeof(AddBankAccount));
        Routing.RegisterRoute(nameof(AddPixKey), typeof(AddPixKey));
        Routing.RegisterRoute(nameof(PanelCollaborator), typeof(PanelCollaborator));
        Routing.RegisterRoute(nameof(CreateEvent), typeof(CreateEvent));
        Routing.RegisterRoute(nameof(ManageEvent), typeof(ManageEvent));
        Routing.RegisterRoute(nameof(ParticipantList), typeof(ParticipantList));
        Routing.RegisterRoute(nameof(EventTeam), typeof(EventTeam));
        Routing.RegisterRoute(nameof(CheckInPage), typeof(CheckInPage));
        Routing.RegisterRoute(nameof(EventAttractions), typeof(EventAttractions));
        Routing.RegisterRoute(nameof(CollaboratorEventDetail), typeof(CollaboratorEventDetail));
        Routing.RegisterRoute(nameof(EventDetail), typeof(EventDetail));
        Routing.RegisterRoute(nameof(ManageTicketsPage), typeof(ManageTicketsPage));
        Routing.RegisterRoute(nameof(CheckoutPage), typeof(CheckoutPage));
        Routing.RegisterRoute(nameof(EmailVerification), typeof(EmailVerification));
        Routing.RegisterRoute(nameof(ForgotPassword), typeof(ForgotPassword));
        Routing.RegisterRoute(nameof(ResetPassword), typeof(ResetPassword));
        Routing.RegisterRoute(nameof(UserInvitations), typeof(UserInvitations));
        Routing.RegisterRoute(nameof(TicketQrCodePage), typeof(TicketQrCodePage));
        Routing.RegisterRoute(nameof(OrderDetailPage), typeof(OrderDetailPage));
    }

    protected override void OnNavigated(ShellNavigatedEventArgs args)
    {
        base.OnNavigated(args);

        if (args.Source != ShellNavigationSource.ShellSectionChanged)
            return;

        var selectedTab = CurrentItem?.CurrentItem;
        if (selectedTab?.Stack.Count is null or 0)
            return;

        var rootRoute = selectedTab.CurrentItem?.Route;
        if (string.IsNullOrEmpty(rootRoute))
            return;

        // Shell keeps a separate detail stack for each tab. An absolute route clears
        // that stack when the tab becomes active again.
        Dispatcher.Dispatch(() => _ = GoToAsync($"{AppRoutes.Main}/{rootRoute}"));
    }
}
