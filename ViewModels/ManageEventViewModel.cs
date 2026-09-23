using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Models;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventId), "EventId")]
public partial class ManageEventViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly IDialogService _dialogs;
    private string? _eventId;
    private EventDetailDto? _currentEvent;

    [ObservableProperty]
    public partial string EventName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventDate { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventImage { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Status { get; set; } = "draft";

    [ObservableProperty]
    public partial string StatusDisplayText { get; set; } = "RASCUNHO";

    [ObservableProperty]
    public partial bool CanEdit { get; set; }

    [ObservableProperty]
    public partial bool CanPublish { get; set; }

    [ObservableProperty]
    public partial bool CanCancel { get; set; }

    [ObservableProperty]
    public partial bool CanDelete { get; set; }

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    public string? EventId
    {
        set
        {
            _eventId = value;
            if (value is not null) _ = LoadEventAsync(value);
        }
    }

    public ManageEventViewModel(IEventsApi eventsApi, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _dialogs = dialogService;
    }

    private async Task LoadEventAsync(string eventId)
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var evt = (await ApiResult.TryExecuteAsync(() => _eventsApi.GetByIdAsync(eventId), "Load event"))?.Data;
            if (evt is null) return;

            _currentEvent = evt;
            EventName = evt.Title;
            EventDate = $"{evt.StartDate.ToLocalTime():dd MMM, yyyy - HH:mm}";
            EventImage = evt.BannerUrl ?? string.Empty;
            Status = evt.Status;
            StatusDisplayText = DomainCatalog.Status(StatusKind.Event, evt.Status).Label;
            UpdatePermissions();
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"ManageEvent LoadEventAsync failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
        }
    }

    private void UpdatePermissions()
    {
        var now = DateTime.UtcNow;
        var startDate = _currentEvent?.StartDate;

        CanEdit = Status switch
        {
            "draft" => true,
            "opened" => startDate is not null && now <= startDate.Value,
            _ => false
        };

        CanPublish = Status == "draft";
        CanCancel = Status == "opened" || Status == "going";
        CanDelete = Status == "draft";
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private async Task PublishEventAsync()
    {
        if (!CanPublish || _eventId is null) return;

        var result = (await ApiResult.TryExecuteAsync(() => _eventsApi.UpdateStatusAsync(_eventId, new UpdateEventStatusDto("opened")), "Publish event"))?.Data;

        if (result is not null)
        {
            Status = "opened";
            StatusDisplayText = "ATIVO";
            UpdatePermissions();
            await _dialogs.ShowToastAsync("Agora seu evento está visível para o público.");
        }
        else
        {
            await _dialogs.ShowErrorAsync(
                "Não foi possível publicar o evento.");
        }
    }

    [RelayCommand]
    private async Task CancelEventAsync()
    {
        if (!CanCancel || _eventId is null) return;

        bool confirm = await _dialogs.ConfirmAsync("Cancelar Evento",
            "Tem certeza que deseja cancelar este evento? Esta ação não pode ser desfeita.",
            "Sim, Cancelar", "Voltar");

        if (!confirm) return;

        var success = await ApiResult.TryExecuteAsync(() => _eventsApi.CancelAsync(_eventId), "Cancel event");
        if (success)
        {
            Status = "canceled";
            StatusDisplayText = "CANCELADO";
            UpdatePermissions();
            await _dialogs.ShowToastAsync("O evento foi cancelado com sucesso.");
        }
        else
        {
            await _dialogs.ShowErrorAsync(
                "Não foi possível cancelar o evento.");
        }
    }

    [RelayCommand]
    private async Task EditEventAsync()
    {
        if (!CanEdit || _eventId is null) return;

        await Shell.Current.GoToAsync(nameof(Views.CreateEvent), new Dictionary<string, object>
        {
            ["EventId"] = _eventId
        });
    }

    [RelayCommand]
    private async Task DeleteEventAsync()
    {
        if (!CanDelete || _eventId is null) return;

        bool confirm = await _dialogs.ConfirmAsync("Excluir Evento",
            "Tem certeza que deseja excluir este evento? Esta ação não pode ser desfeita.",
            "Sim, Excluir", "Cancelar");

        if (!confirm) return;

        var success = await ApiResult.TryExecuteAsync(() => _eventsApi.DeleteAsync(_eventId), "Delete event");
        if (success)
        {
            await _dialogs.ShowToastAsync("O evento foi excluído com sucesso.");
            await Shell.Current.GoToAsync("..");
        }
        else
        {
            await _dialogs.ShowErrorAsync(
                "Não foi possível excluir o evento.");
        }
    }

    [RelayCommand]
    private async Task CheckInAsync()
    {
        if (_eventId is null) return;

        await Shell.Current.GoToAsync(nameof(Views.CheckInPage), new Dictionary<string, object>
        {
            ["EventId"] = _eventId
        });
    }

    [RelayCommand]
    private async Task ParticipantListAsync()
    {
        if (_eventId is null) return;

        await Shell.Current.GoToAsync(nameof(Views.ParticipantList), new Dictionary<string, object>
        {
            ["EventId"] = _eventId,
            ["EventName"] = EventName
        });
    }

    [RelayCommand]
    private async Task TeamAsync()
    {
        if (_eventId is null) return;

        await Shell.Current.GoToAsync(nameof(Views.EventTeam), new Dictionary<string, object>
        {
            ["EventId"] = _eventId,
            ["EventName"] = EventName,
            ["EventStatus"] = Status
        });
    }

    [RelayCommand]
    private async Task AttractionsAsync()
    {
        if (_eventId is null) return;

        await Shell.Current.GoToAsync(nameof(Views.EventAttractions), new Dictionary<string, object>
        {
            ["EventId"] = _eventId
        });
    }

    [RelayCommand]
    private async Task ManageTicketsAsync()
    {
        if (_eventId is null) return;

        await Shell.Current.GoToAsync(nameof(Views.ManageTicketsPage), new Dictionary<string, object>
        {
            ["EventId"] = _eventId
        });
    }
}
