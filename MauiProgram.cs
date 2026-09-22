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
			.UseMauiCommunityToolkit()
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
		builder.Services.AddRefitClient<IAuthApi>(RefitConfig.CreateSettings())
			.ConfigureHttpClient(c => c.BaseAddress = new Uri(baseUrl));
		builder.Services.AddRefitClient<IUsersApi>(RefitConfig.CreateSettings())
			.ConfigureHttpClient(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<PaymentInfoApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddRefitClient<IStatesApi>(RefitConfig.CreateSettings())
			.ConfigureHttpClient(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddRefitClient<IEventsApi>(RefitConfig.CreateSettings())
			.ConfigureHttpClient(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<AttractionsApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<TicketTypesApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<OrdersApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<TicketsApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<EventStaffApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<StaffInvitesApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<FavoritesApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<CheckInApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<EventRatingsApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<AgePoliciesApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<StorageApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddHttpClient<ParticipantsApiClient>(c => c.BaseAddress = new Uri(baseUrl))
			.AddHttpMessageHandler<AuthTokenHandler>();

		builder.Services.AddSingleton<IAuthService, AuthService>();
		builder.Services.AddTransient<PaymentInfoService>();
		builder.Services.AddTransient<AttractionsService>();
		builder.Services.AddTransient<FavoritesService>();
		builder.Services.AddTransient<TicketsService>();
		builder.Services.AddTransient<OrdersService>();
		builder.Services.AddTransient<CheckInService>();
		builder.Services.AddTransient<AgePolicyService>();
		builder.Services.AddTransient<StorageService>();
		builder.Services.AddTransient<ParticipantsService>();
		builder.Services.AddTransient<EventRatingsService>();

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
}
