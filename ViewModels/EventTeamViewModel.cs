using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventName), nameof(EventName))]
[QueryProperty(nameof(EventId), nameof(EventId))]
[QueryProperty(nameof(EventStatus), nameof(EventStatus))]
public partial class EventTeamViewModel : ObservableObject
{
    private readonly IEventStaffApi _staffApi;
    private readonly IStaffInvitesApi _invitesApi;
    private readonly IDialogService _dialogs;

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
        IStaffInvitesApi invitesApi,
        IDialogService dialogService)
    {
        _staffApi = staffApi;
        _invitesApi = invitesApi;
        _dialogs = dialogService;
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
                limit: 10), "Load team");

            var invites = await ApiResult.TryExecuteAsync(() => _invitesApi.GetAllAsync(
                eventId,
                invitationStatus: "pending",
                page: 1,
                limit: 10), "Load invites");

            if (eventStaff is null || invites is null)
            {
                await _dialogs.ShowErrorAsync("Não foi possível carregar a equipe.");
                return;
            }

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
            await _dialogs.ShowErrorAsync(
                $"EventTeam LoadDataAsync failed: {ex.Message}");
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
            await _dialogs.ShowErrorAsync("Informe um e-mail válido.");

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
            var created = await ApiResult.TryExecuteAsync(() => _invitesApi.CreateAsync(EventId, dto), "Invite member");
            if (created is null)
            {
                await _dialogs.ShowErrorAsync("Não foi possível enviar o convite.");
                return;
            }

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
            await _dialogs.ShowErrorAsync(
                $"EventTeam InviteAsync failed: {ex.Message}");
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
            var updated = await ApiResult.TryExecuteAsync(
                () => _staffApi.UpdateAccessLevelAsync(EditingMember.StaffId, dto), "Update access level");
            if (updated is null)
            {
                await _dialogs.ShowErrorAsync("Não foi possível atualizar a função.");
                return;
            }

            EditingMember.Role = SelectedRole;
            EditingMember = null;
            SelectedRole = "Credenciamento";
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync(
                $"Falha ao atualizar função: {ex.Message}");
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
                var canceled = await ApiResult.TryExecuteAsync(() => _invitesApi.CancelAsync(member.InvitationId), "Cancel invite");
                if (canceled is null)
                {
                    await _dialogs.ShowErrorAsync("Não foi possível cancelar o convite.");
                    return;
                }

                PendingInvites.Remove(member);

                OnPropertyChanged(nameof(PendingCount));
            }
            else if (!string.IsNullOrEmpty(member.StaffId))
            {
                if (!await ApiResult.TryExecuteAsync(() => _staffApi.DeleteAsync(member.StaffId), "Remove member"))
                {
                    await _dialogs.ShowErrorAsync("Não foi possível remover o membro.");
                    return;
                }

                ActiveTeam.Remove(member);

                OnPropertyChanged(nameof(ActiveCount));
            }
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync(
                $"EventTeam RemoveMember failed: {ex.Message}");
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