using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Models;
using CoreventApp.Helpers;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public record StatusFilterChip(string Label, string? StatusValue, bool IsSelected);

public partial class PanelOrganizerViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly PaymentInfoService _paymentInfoService;
    private readonly IDialogService _dialogs;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool HasPaymentInfo { get; set; }

    public ObservableCollection<EventListItemDto> AllEvents { get; } = new();
    public ObservableCollection<EventListItemDto> FilteredEvents { get; } = new();
    public ObservableCollection<StatusFilterChip> FilterChips { get; } = new();

    public PanelOrganizerViewModel(IEventsApi eventsApi, PaymentInfoService paymentInfoService, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _paymentInfoService = paymentInfoService;
        _dialogs = dialogService;

        FilterChips.Add(new StatusFilterChip("Todos", null, true));
        FilterChips.AddRange(DomainCatalog.EventStatuses.Select(x => new StatusFilterChip(x.Label, x.ApiValue, false)));
    }

    [RelayCommand]
    private async Task LoadAsync()
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var events = await LoadOrganizerEventsAsync();

            AllEvents.ReplaceWith(events);

            ApplyFilter(null);

            var paymentInfos = await _paymentInfoService.GetAllAsync();
            HasPaymentInfo = paymentInfos.Count > 0;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync("Não foi possível carregar seus eventos.");
            Debug.WriteLine($"PanelOrganizer LoadAsync failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private void FilterByStatus(StatusFilterChip? chip)
    {
        if (chip is null) return;

        foreach (var c in FilterChips.ToArray())
        {
            if (c == chip)
                FilterChips[FilterChips.IndexOf(c)] = c with { IsSelected = true };
            else
                FilterChips[FilterChips.IndexOf(c)] = c with { IsSelected = false };
        }

        ApplyFilter(chip?.StatusValue);
    }

    private async Task<List<EventListItemDto>> LoadOrganizerEventsAsync()
    {
        var statuses = DomainCatalog.EventStatuses.Select(x => x.ApiValue);
        var tasks = statuses.Select(status =>
            ApiResult.TryExecuteAsync(
                () => _eventsApi.GetMyOrganizerEventsAsync(page: 1, limit: 100, status: status),
                "Load organizer events"));
        var results = await Task.WhenAll(tasks);
        return results.Where(r => r is not null).SelectMany(r => r!.Data).ToList();
    }

    private void ApplyFilter(string? statusValue)
    {
        var filtered = statusValue is null
            ? AllEvents
            : AllEvents.Where(e => e.Status == statusValue);
        FilteredEvents.ReplaceWith(filtered);
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private async Task ConfigureTransferAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.TransferSettings));
    }

    [RelayCommand]
    private async Task NewEventAsync()
    {
        if (!HasPaymentInfo)
        {
            await _dialogs.ShowAlertAsync("Atenção", "Configure seus dados de repasse antes de criar um evento.");
            return;
        }

        await Shell.Current.GoToAsync(nameof(Views.CreateEvent));
    }

    [RelayCommand]
    private async Task SelectEventAsync(EventListItemDto? eventItem)
    {
        if (eventItem is null) return;

        await Shell.Current.GoToAsync(nameof(Views.ManageEvent), new Dictionary<string, object>
        {
            [nameof(ManageEventViewModel.EventId)] = eventItem.Id
        });
    }
}
