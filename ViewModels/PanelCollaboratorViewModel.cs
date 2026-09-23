using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public partial class PanelCollaboratorViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly IStaffInvitesApi _invitesApi;
    private readonly IDialogService _dialogs;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsAgendaVisible { get; set; } = true;

    [ObservableProperty]
    public partial bool IsHistoricoVisible { get; set; } = false;

    [ObservableProperty]
    public partial bool HasPendingInvites { get; set; }

    [ObservableProperty]
    public partial int PendingInvitesCount { get; set; }

    public ObservableCollection<CollaboratorEvent> EventsToday { get; } = new();
    public ObservableCollection<CollaboratorEvent> UpcomingEvents { get; } = new();
    public ObservableCollection<CollaboratorEvent> PastEvents { get; } = new();

    [ObservableProperty]
    public partial bool HasEventsToday { get; set; }

    [ObservableProperty]
    public partial bool HasUpcomingEvents { get; set; }

    [ObservableProperty]
    public partial bool HasPastEvents { get; set; }

    public PanelCollaboratorViewModel(IEventsApi eventsApi, IStaffInvitesApi invitesApi, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _invitesApi = invitesApi;
        _dialogs = dialogService;
    }

    [RelayCommand]
    private async Task LoadAsync()
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var staffEvents = await LoadStaffEventsAsync();

            EventsToday.Clear();
            UpcomingEvents.Clear();
            PastEvents.Clear();

            foreach (var item in staffEvents)
            {
                var ce = MapToCollaboratorEvent(item);

                var localDate = item.StartDate.ToLocalTime().Date;
                if (localDate == DateTime.Today)
                    EventsToday.Add(ce);
                else if (localDate > DateTime.Today)
                    UpcomingEvents.Add(ce);
                else
                    PastEvents.Add(ce);
            }

            HasEventsToday = EventsToday.Count > 0;
            HasUpcomingEvents = UpcomingEvents.Count > 0;
            HasPastEvents = PastEvents.Count > 0;

            var invites = await ApiResult.TryExecuteAsync(
                () => _invitesApi.GetMyInvitationsAsync(page: 1, limit: 10, invitationStatus: "pending"),
                "Load pending invites");
            PendingInvitesCount = invites?.Meta.TotalItems ?? 0;
            HasPendingInvites = PendingInvitesCount > 0;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"PanelCollaborator LoadAsync failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
        }
    }

    private async Task<List<StaffEventListItemDto>> LoadStaffEventsAsync()
    {
        var statuses = new[] { "opened", "going", "finished" };
        var tasks = statuses.Select(status =>
            ApiResult.TryExecuteAsync(
                () => _eventsApi.GetMyStaffEventsAsync(page: 1, limit: 100, status: status),
                "Load staff events"));
        var results = await Task.WhenAll(tasks);
        return results.Where(r => r is not null).SelectMany(r => r!.Data).ToList();
    }

    private static CollaboratorEvent MapToCollaboratorEvent(StaffEventListItemDto item)
    {
        var isCheckin = item.AccessLevel == "checkin";
        var role = isCheckin ? "CREDENCIAMENTO" : "ORGANIZAÇÃO";
        var roleColor = isCheckin ? "#E0F2FE" : "#F3E8FF";
        var roleTextColor = isCheckin ? "#0284C7" : "#9333EA";

        return new CollaboratorEvent
        {
            Id = item.Id,
            ImageUrl = "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400&auto=format&fit=crop",
            Title = item.Title,
            Date = item.StartDate.ToLocalTime().ToString("dd MMM, yyyy"),
            Role = role,
            RoleColor = roleColor,
            RoleTextColor = roleTextColor,
            HasActionButton = item.StartDate.ToLocalTime().Date == DateTime.Today && isCheckin,
            ParticipantCount = 0
        };
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private void SelectAgenda()
    {
        IsAgendaVisible = true;
        IsHistoricoVisible = false;
    }

    [RelayCommand]
    private void SelectHistorico()
    {
        IsAgendaVisible = false;
        IsHistoricoVisible = true;
    }

    [RelayCommand]
    private async Task RealizarCredenciamentoAsync()
    {
        await _dialogs.ShowAlertAsync("Credenciamento", "Abrir câmera para leitura de QR Code");
    }

    [RelayCommand]
    private async Task OpenEventDetailAsync(CollaboratorEvent evt)
    {
        await Shell.Current.GoToAsync(nameof(Views.CollaboratorEventDetail), new ShellNavigationQueryParameters
        {
            [nameof(CollaboratorEventDetailViewModel.EventId)] = evt.Id,
            [nameof(CollaboratorEventDetailViewModel.EventTitle)] = evt.Title,
            [nameof(CollaboratorEventDetailViewModel.EventDate)] = evt.Date,
            [nameof(CollaboratorEventDetailViewModel.EventImage)] = evt.ImageUrl,
            [nameof(CollaboratorEventDetailViewModel.EventRole)] = evt.Role,
            [nameof(CollaboratorEventDetailViewModel.EventRoleColor)] = evt.RoleColor,
            [nameof(CollaboratorEventDetailViewModel.EventRoleTextColor)] = evt.RoleTextColor,
            [nameof(CollaboratorEventDetailViewModel.ParticipantCount)] = evt.ParticipantCount
        });
    }

    [RelayCommand]
    private async Task OpenInvitationsAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.UserInvitations));
    }
}
