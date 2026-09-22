using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventId), "EventId")]
public partial class CheckInViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly ICheckInApi _checkInApi;
    private readonly IDialogService _dialogs;
    private string? _eventId;

    [ObservableProperty]
    public partial string EventName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string CheckInCount { get; set; } = "0/0";

    [ObservableProperty]
    public partial string ResultMessage { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsResultVisible { get; set; }

    [ObservableProperty]
    public partial bool IsResultSuccess { get; set; }

    [ObservableProperty]
    public partial bool IsScannerBlocked { get; set; } = true;

    [ObservableProperty]
    public partial bool IsScanning { get; set; }

    private string _eventStatus = string.Empty;

    public string? EventId
    {
        set
        {
            _eventId = value;
            if (value is not null) _ = LoadEventAsync(value);
        }
    }

    public CheckInViewModel(IEventsApi eventsApi, ICheckInApi checkInApi, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _checkInApi = checkInApi;
        _dialogs = dialogService;
    }

    private async Task LoadEventAsync(string eventId)
    {
        try
        {
            var evt = (await ApiResult.TryExecuteAsync(() => _eventsApi.GetByIdAsync(eventId), "Load event"))?.Data;
            if (evt is null) return;

            EventName = evt.Title;
            _eventStatus = evt.Status;

            var canCheckIn = evt.Status is "opened" or "going";
            IsScannerBlocked = !canCheckIn;
            IsScanning = canCheckIn;

            if (!canCheckIn)
            {
                ResultMessage = "Este evento não está disponível para check-in no momento.";
                IsResultVisible = true;
                IsResultSuccess = false;
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"CheckIn LoadEventAsync failed: {ex.Message}");
            await _dialogs.ShowErrorAsync("Não foi possível carregar os dados do evento.");
        }
    }

    [RelayCommand]
    private async Task ProcessBarcodeAsync(string? barcode)
    {
        if (string.IsNullOrWhiteSpace(barcode)) return;
        if (IsResultVisible) return;

        if (_eventStatus is not ("opened" or "going"))
            return;

        IsScanning = false;

        var data = (await ApiResult.TryExecuteAsync(
            () => _checkInApi.CheckinAsync(_eventId!, new CheckinDto(barcode)), "Check-in"))?.Data;

        if (data is not null)
        {
            IsResultSuccess = true;
            ResultMessage = $"{data.User.Name} — {data.Event.Title}";
        }
        else
        {
            IsResultSuccess = false;
            ResultMessage = "QR Code inválido ou ingresso já utilizado.";
        }

        IsResultVisible = true;
    }

    [RelayCommand]
    private void DismissResult()
    {
        IsResultVisible = false;
        ResultMessage = string.Empty;
        IsScanning = true;
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }
}
