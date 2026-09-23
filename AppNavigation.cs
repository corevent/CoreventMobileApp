using CoreventApp.ViewModels;

namespace CoreventApp;

/// <summary>Shared navigation for destinations with repeated parameters.</summary>
public static class AppNavigation
{
    public static Task ToEventAsync(string eventId) =>
        Shell.Current.GoToAsync(nameof(Views.EventDetail), new ShellNavigationQueryParameters
        {
            [nameof(EventDetailViewModel.EventId)] = eventId
        });

    public static Task ToParticipantsAsync(string eventId, string eventName) =>
        Shell.Current.GoToAsync(nameof(Views.ParticipantList), new ShellNavigationQueryParameters
        {
            [nameof(ParticipantListViewModel.EventId)] = eventId,
            [nameof(ParticipantListViewModel.EventName)] = eventName
        });

    public static Task ToCheckInAsync(string eventId) =>
        Shell.Current.GoToAsync(nameof(Views.CheckInPage), new ShellNavigationQueryParameters
        {
            [nameof(CheckInViewModel.EventId)] = eventId
        });
}
