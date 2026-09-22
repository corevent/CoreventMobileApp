using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventName), nameof(EventName))]
[QueryProperty(nameof(EventId), nameof(EventId))]
[QueryProperty(nameof(EventStatus), nameof(EventStatus))]
public partial class EventTeamViewModel : ObservableObject
{
    private readonly IEventStaffApi _staffApi;
    private readonly IStaffInvitesApi _invitesApi;

    private string? _eventId;

    [ObservableProperty]
    public partial string EventName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventStatus { get; set; } = string.Empty;

    partial void OnEventStatusChanged(string value)
    {
        OnPropertyChanged(nameof(CanInvite));
    }

    public bool CanInvite => EventStatus == "opened";

    public string? EventId
    {
        get => _eventId;
        set
        {
            _eventId = value;

            if (!string.IsNullOrWhiteSpace(value))
            {
                _ = LoadDataAsync(value);
            }
        }
    }

    [ObservableProperty]
    public partial string InviteEmail { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string SelectedRole { get; set; } = "Credenciamento";

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial TeamMember? EditingMember { get; set; }

    partial void OnEditingMemberChanged(TeamMember? value)
    {
        OnPropertyChanged(nameof(IsEditingAccessLevel));
        OnPropertyChanged(nameof(IsInviteFormVisible));
        OnPropertyChanged(nameof(IsEditFormVisible));
        OnPropertyChanged(nameof(AccessLevelFormTitle));
    }

    public bool IsEditingAccessLevel => EditingMember is not null;
    public bool IsInviteFormVisible => EditingMember is null;
    public bool IsEditFormVisible => EditingMember is not null;

    public string AccessLevelFormTitle => EditingMember is not null
        ? $"Editar {EditingMember.Name}"
        : "Convidar Colaborador";

    public ObservableCollection<TeamMember> PendingInvites { get; } = new();
    public ObservableCollection<TeamMember> ActiveTeam { get; } = new();

    public int PendingCount => PendingInvites.Count;
    public int ActiveCount => ActiveTeam.Count;

    public EventTeamViewModel(
        IEventStaffApi staffApi,
        IStaffInvitesApi invitesApi)
    {
        _staffApi = staffApi;
        _invitesApi = invitesApi;
    }

    private async Task LoadDataAsync(string eventId)
    {
        if (IsLoading) return;

        IsLoading = true;

        try
        {
            var eventStaff = await ApiResult.TryExecuteAsync(() => _staffApi.GetAllAsync(
                eventId,
                page: 1,
                limit: 10), "Load team")
                ?? throw new InvalidOperationException("Load team failed.");

            var invites = await ApiResult.TryExecuteAsync(() => _invitesApi.GetAllAsync(
                eventId,
                invitationStatus: "pending",
                page: 1,
                limit: 10), "Load invites")
                ?? throw new InvalidOperationException("Load invites failed.");

            PendingInvites.Clear();

            foreach (var invite in invites.Data)
            {
                PendingInvites.Add(new TeamMember
                {
                    Name = invite.User.Name ?? invite.User.Email,
                    Email = invite.User.Email,
                    Role = invite.OriginalAccessLevel == "checkin"
                        ? "Credenciamento"
                        : "Organização",
                    IsPending = true,
                    InvitationId = invite.Id
                });
            }

            ActiveTeam.Clear();

            foreach (var staff in eventStaff.Data)
            {
                ActiveTeam.Add(new TeamMember
                {
                    Name = staff.User.Name ?? staff.User.Email,
                    Email = staff.User.Email,
                    Role = staff.AccessLevel == "checkin"
                        ? "Credenciamento"
                        : "Organização",
                    IsPending = false,
                    StaffId = staff.Id
                });
            }

            OnPropertyChanged(nameof(PendingCount));
            OnPropertyChanged(nameof(ActiveCount));
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlertAsync(
                "Erro",
                $"EventTeam LoadDataAsync failed: {ex.Message}",
                "OK");
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private void ToggleRole(string role)
    {
        SelectedRole = role;
    }

    [RelayCommand]
    private void EditAccessLevel(TeamMember member)
    {
        if (member.IsPending || string.IsNullOrEmpty(member.StaffId))
            return;

        EditingMember = member;
        SelectedRole = member.Role;
    }

    [RelayCommand]
    private void CancelEditAccessLevel()
    {
        EditingMember = null;
        SelectedRole = "Credenciamento";
    }

    [RelayCommand]
    private async Task InviteAsync()
    {
        if (IsEditingAccessLevel && EditingMember is not null)
        {
            await SaveAccessLevelAsync();
            return;
        }

        if (string.IsNullOrWhiteSpace(InviteEmail) ||
            string.IsNullOrWhiteSpace(EventId))
        {
            return;
        }

        if (!ValidationHelper.IsValidEmail(InviteEmail))
        {
            await Shell.Current.DisplayAlertAsync(
                "Erro",
                "Informe um e-mail válido.",
                "OK");

            return;
        }

        var accessLevel = SelectedRole == "Credenciamento"
            ? "checkin"
            : "readonly";

        var dto = new CreateEventStaffInvitationDto(
            InviteEmail.Trim(),
            accessLevel);

        try
        {
            _ =             _ = (await ApiResult.TryExecuteAsync(() => _invitesApi.CreateAsync(EventId, dto), "Invite member"))
                ?? throw new InvalidOperationException("Invite failed.");

            PendingInvites.Add(new TeamMember
            {
                Email = InviteEmail.Trim(),
                Role = SelectedRole,
                IsPending = true
            });

            InviteEmail = string.Empty;

            OnPropertyChanged(nameof(PendingCount));
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlertAsync(
                "Erro",
                $"EventTeam InviteAsync failed: {ex.Message}",
                "OK");
        }
    }

    private async Task SaveAccessLevelAsync()
    {
        if (EditingMember is null || string.IsNullOrEmpty(EditingMember.StaffId))
            return;

        var accessLevel = SelectedRole == "Credenciamento"
            ? "checkin"
            : "readonly";

        var oldRole = EditingMember.Role;

        try
        {
            var dto = new UpdateEventStaffAccessLevelDto(accessLevel);
            _ =             _ = (await ApiResult.TryExecuteAsync(
                () => _staffApi.UpdateAccessLevelAsync(EditingMember.StaffId, dto), "Update access level"))
                ?? throw new InvalidOperationException("Update access level failed.");

            EditingMember.Role = SelectedRole;
            EditingMember = null;
            SelectedRole = "Credenciamento";
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlertAsync(
                "Erro",
                $"Falha ao atualizar função: {ex.Message}",
                "OK");
        }
    }

    [RelayCommand]
    private async Task RemoveMember(TeamMember member)
    {
        try
        {
            if (member.IsPending &&
                !string.IsNullOrEmpty(member.InvitationId))
            {
                _ =                 _ = (await ApiResult.TryExecuteAsync(() => _invitesApi.CancelAsync(member.InvitationId), "Cancel invite"))
                    ?? throw new InvalidOperationException("Cancel invite failed.");

                PendingInvites.Remove(member);

                OnPropertyChanged(nameof(PendingCount));
            }
            else if (!string.IsNullOrEmpty(member.StaffId))
            {
                if (!await ApiResult.TryExecuteAsync(() => _staffApi.DeleteAsync(member.StaffId), "Remove member"))
                    throw new InvalidOperationException("Remove member failed.");

                ActiveTeam.Remove(member);

                OnPropertyChanged(nameof(ActiveCount));
            }
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlertAsync(
                "Erro",
                $"EventTeam RemoveMember failed: {ex.Message}",
                "OK");
        }
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }
}

public partial class TeamMember : ObservableObject
{
    [ObservableProperty]
    public partial string Name { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Email { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Role { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsPending { get; set; }

    public string? StaffId { get; set; }
    public string? InvitationId { get; set; }

    public string Initial =>
        !string.IsNullOrEmpty(Name)
            ? Name[..1].ToUpper()
            : !string.IsNullOrEmpty(Email)
                ? Email[..1].ToUpper()
                : "?";
}