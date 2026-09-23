using CommunityToolkit.Maui;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using MauiIcons.Cupertino;
using Microsoft.Extensions.Logging;
using Refit;
using ZXing.Net.Maui.Controls;

namespace CoreventApp;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiCommunityToolkit(options => options.SetShouldEnableSnackbarOnWindows(true))
            .UseBarcodeReader()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                fonts.AddFont("PlusJakartaSans-VariableFont_wght.ttf", "Plus Jakarta Sans");
            })
            .UseCupertinoMauiIcons();

        builder.Services.AddSingleton<AppShell>();

        // Services
        builder.Services.AddSingleton<TokenService>();
        builder.Services.AddTransient<AuthTokenHandler>();

        string baseUrl = "https://corevent-app-fatec-d78bb2efd71a.herokuapp.com/";
        builder.Services.AddHttpClient(AuthTokenHandler.RefreshClientName, c => c.BaseAddress = new Uri(baseUrl));
        builder.Services.AddHttpClient<IStorageUploadService, StorageUploadService>("storage-upload", client =>
        {
            client.Timeout = TimeSpan.FromSeconds(60);
        });
        builder.Services.AddRefitClient<IAuthApi>(RefitConfig.CreateSettings())
            .ConfigureHttpClient(c => c.BaseAddress = new Uri(baseUrl));

        builder.Services.AddAuthenticatedRefitClient<IUsersApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IPaymentInfoApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IStatesApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IEventsApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IAttractionsApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<ITicketTypesApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IOrdersApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<ITicketsApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IEventStaffApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IStaffInvitesApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IFavoritesApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<ICheckInApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IEventRatingsApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IAgePoliciesApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IStorageApi>(baseUrl);
        builder.Services.AddAuthenticatedRefitClient<IParticipantsApi>(baseUrl);

        builder.Services.AddSingleton<IAuthService, AuthService>();
        builder.Services.AddSingleton<IDialogService, DialogService>();
        builder.Services.AddTransient<PaymentInfoService>();
        builder.Services.AddTransient<FavoritesService>();
        builder.Services.AddTransient<StorageService>();

        // ViewModels
        builder.Services.AddTransient<ViewModels.WelcomeViewModel>();
        builder.Services.AddTransient<ViewModels.LoginViewModel>();
        builder.Services.AddTransient<ViewModels.RegisterViewModel>();
        builder.Services.AddTransient<ViewModels.UpdatePasswordViewModel>();
        builder.Services.AddTransient<ViewModels.HomeViewModel>();
        builder.Services.AddTransient<ViewModels.ExploreViewModel>();
        builder.Services.AddTransient<ViewModels.TicketsViewModel>();
        builder.Services.AddTransient<ViewModels.ProfileViewModel>();
        builder.Services.AddTransient<ViewModels.PrivacyViewModel>();
        builder.Services.AddTransient<ViewModels.EditProfileViewModel>();
        builder.Services.AddTransient<ViewModels.FavoritesViewModel>();
        builder.Services.AddTransient<ViewModels.PanelCollaboratorViewModel>();
        builder.Services.AddTransient<ViewModels.PanelOrganizerViewModel>();
        builder.Services.AddTransient<ViewModels.TransferSettingsViewModel>();
        builder.Services.AddTransient<ViewModels.EmailVerificationViewModel>();
        builder.Services.AddTransient<ViewModels.ForgotPasswordViewModel>();
        builder.Services.AddTransient<ViewModels.ResetPasswordViewModel>();
        builder.Services.AddTransient<ViewModels.AddBankAccountViewModel>();
        builder.Services.AddTransient<ViewModels.AddPixKeyViewModel>();
        builder.Services.AddTransient<ViewModels.PurchaseHistoryViewModel>();
        builder.Services.AddTransient<ViewModels.ReviewsViewModel>();
        builder.Services.AddTransient<ViewModels.CreateEventViewModel>();
        builder.Services.AddTransient<ViewModels.ManageEventViewModel>();
        builder.Services.AddTransient<ViewModels.ParticipantListViewModel>();
        builder.Services.AddTransient<ViewModels.EventTeamViewModel>();
        builder.Services.AddTransient<ViewModels.CheckInViewModel>();
        builder.Services.AddTransient<ViewModels.EventAttractionsViewModel>();
        builder.Services.AddTransient<ViewModels.SettingsViewModel>();
        builder.Services.AddTransient<ViewModels.CollaboratorEventDetailViewModel>();
        builder.Services.AddTransient<ViewModels.EventDetailViewModel>();
        builder.Services.AddTransient<ViewModels.ManageTicketsViewModel>();
        builder.Services.AddTransient<ViewModels.CheckoutViewModel>();
        builder.Services.AddTransient<ViewModels.UserInvitationsViewModel>();
        builder.Services.AddTransient<ViewModels.TicketQrCodeViewModel>();
        builder.Services.AddTransient<ViewModels.OrderDetailViewModel>();

        // Views
        builder.Services.AddTransient<Views.TicketQrCodePage>();
        builder.Services.AddTransient<Views.OrderDetailPage>();
        builder.Services.AddTransient<Views.CreateEvent>();
        builder.Services.AddTransient<Views.ManageEvent>();
        builder.Services.AddTransient<Views.ParticipantList>();
        builder.Services.AddTransient<Views.EventTeam>();
        builder.Services.AddTransient<Views.CheckInPage>();
        builder.Services.AddTransient<Views.EventAttractions>();
        builder.Services.AddTransient<Views.Welcome>();
        builder.Services.AddTransient<Views.Login>();
        builder.Services.AddTransient<Views.Register>();
        builder.Services.AddTransient<Views.UpdatePassword>();
        builder.Services.AddTransient<Views.Home>();
        builder.Services.AddTransient<Views.Explore>();
        builder.Services.AddTransient<Views.Tickets>();
        builder.Services.AddTransient<Views.Profile>();
        builder.Services.AddTransient<Views.Privacy>();
        builder.Services.AddTransient<Views.EditProfile>();
        builder.Services.AddTransient<Views.Favorites>();
        builder.Services.AddTransient<Views.PanelCollaborator>();
        builder.Services.AddTransient<Views.PanelOrganizer>();
        builder.Services.AddTransient<Views.TransferSettings>();
        builder.Services.AddTransient<Views.AddBankAccount>();
        builder.Services.AddTransient<Views.AddPixKey>();
        builder.Services.AddTransient<Views.PurchaseHistory>();
        builder.Services.AddTransient<Views.EmailVerification>();
        builder.Services.AddTransient<Views.ForgotPassword>();
        builder.Services.AddTransient<Views.ResetPassword>();
        builder.Services.AddTransient<Views.Reviews>();
        builder.Services.AddTransient<Views.Settings>();
        builder.Services.AddTransient<Views.CollaboratorEventDetail>();
        builder.Services.AddTransient<Views.EventDetail>();
        builder.Services.AddTransient<Views.ManageTicketsPage>();
        builder.Services.AddTransient<Views.CheckoutPage>();
        builder.Services.AddTransient<Views.UserInvitations>();

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }

    private static IHttpClientBuilder AddAuthenticatedRefitClient<T>(this IServiceCollection services, string baseUrl) where T : class
    {
        return services.AddRefitClient<T>(RefitConfig.CreateSettings())
            .ConfigureHttpClient(c => c.BaseAddress = new Uri(baseUrl))
            .AddHttpMessageHandler<AuthTokenHandler>();
    }
}
