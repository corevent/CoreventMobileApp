using System.Diagnostics;
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public partial class UserInvitationItem : ObservableObject
{
    [ObservableProperty]
    public partial string Id { get; set; }

    [ObservableProperty]
    public partial string EventName { get; set; }

    [ObservableProperty]
    public partial string OrganizerName { get; set; }

    [ObservableProperty]
    public partial string Role { get; set; }

    [ObservableProperty]
    public partial string Status { get; set; }

    [ObservableProperty]
    public partial bool IsPending { get; set; }

    [ObservableProperty]
    public partial bool IsAccepted { get; set; }

    [ObservableProperty]
    public partial bool IsRejected { get; set; }

    [ObservableProperty]
    public partial string RoleColor { get; set; }

    [ObservableProperty]
    public partial string RoleTextColor { get; set; }

    [ObservableProperty]
    public partial string EventInitial { get; set; }

    public UserInvitationItem(UserInvitationDto dto)
    {
        Id = dto.Id;
        EventName = dto.Event.Title;
        OrganizerName = dto.Event.Organizer.Name;
        Role = dto.OriginalAccessLevel == "checkin" ? "Credenciamento" : "Organização";
        RoleColor = dto.OriginalAccessLevel == "checkin" ? "#E0F2FE" : "#F3E8FF";
        RoleTextColor = dto.OriginalAccessLevel == "checkin" ? "#0284C7" : "#9333EA";
        EventInitial = !string.IsNullOrEmpty(dto.Event.Title) ? dto.Event.Title[..1].ToUpper() : "?";
        Status = dto.InvitationStatus switch
        {
            "pending" => "Pendente",
            "accepted" => "Aceito",
            "rejected" => "Recusado",
            _ => dto.InvitationStatus
        };
        IsPending = dto.InvitationStatus == "pending";
        IsAccepted = dto.InvitationStatus == "accepted";
        IsRejected = dto.InvitationStatus == "rejected";
    }
}

public partial class UserInvitationsViewModel : ObservableObject
{
    private readonly IStaffInvitesApi _invitesApi;
    private readonly IDialogService _dialogs;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsRefreshing { get; set; }

    [ObservableProperty]
    public partial bool HasInvitations { get; set; }

    [ObservableProperty]
    public partial bool HasPending { get; set; }

    [ObservableProperty]
    public partial bool HasAccepted { get; set; }

    [ObservableProperty]
    public partial bool HasRejected { get; set; }

    public ObservableCollection<UserInvitationItem> PendingInvitations { get; } = new();
    public ObservableCollection<UserInvitationItem> AcceptedInvitations { get; } = new();
    public ObservableCollection<UserInvitationItem> RejectedInvitations { get; } = new();

    public UserInvitationsViewModel(IStaffInvitesApi invitesApi, IDialogService dialogService)
    {
        _invitesApi = invitesApi;
        _dialogs = dialogService;
    }

    [RelayCommand]
    private async Task LoadInvitationsAsync()
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var pendingTask = _invitesApi.GetMyInvitationsAsync(page: 1, limit: 50, invitationStatus: "pending");
            var acceptedTask = _invitesApi.GetMyInvitationsAsync(page: 1, limit: 50, invitationStatus: "accepted");
            var rejectedTask = _invitesApi.GetMyInvitationsAsync(page: 1, limit: 50, invitationStatus: "rejected");

            await Task.WhenAll(pendingTask, acceptedTask, rejectedTask);

            PendingInvitations.Clear();
            AcceptedInvitations.Clear();
            RejectedInvitations.Clear();

            var pending = await pendingTask;
            var accepted = await acceptedTask;
            var rejected = await rejectedTask;

            foreach (var item in pending.Data)
                PendingInvitations.Add(new UserInvitationItem(item));

            foreach (var item in accepted.Data)
                AcceptedInvitations.Add(new UserInvitationItem(item));

            foreach (var item in rejected.Data)
                RejectedInvitations.Add(new UserInvitationItem(item));

            HasPending = PendingInvitations.Count > 0;
            HasAccepted = AcceptedInvitations.Count > 0;
            HasRejected = RejectedInvitations.Count > 0;
            HasInvitations = HasPending || HasAccepted || HasRejected;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"Não foi possível carregar convites: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
            IsRefreshing = false;
        }
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        IsRefreshing = true;
        await LoadInvitationsAsync();
    }

    [RelayCommand]
    private async Task AcceptInvitationAsync(UserInvitationItem item)
    {
        try
        {
            await _invitesApi.AcceptAsync(item.Id);
            await _dialogs.ShowToastAsync($"Você agora faz parte da equipe de \"{item.EventName}\"!");
            await LoadInvitationsAsync();
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"Não foi possível aceitar o convite: {ex.Message}");
        }
    }

    [RelayCommand]
    private async Task RejectInvitationAsync(UserInvitationItem item)
    {
        try
        {
            await _invitesApi.RejectAsync(item.Id);
            await _dialogs.ShowToastAsync($"Convite para \"{item.EventName}\" recusado.");
            await LoadInvitationsAsync();
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"Não foi possível recusar o convite: {ex.Message}");
        }
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }
}
