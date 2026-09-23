using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public partial class HomeViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly IAuthService _authService;
    private readonly IDialogService _dialogs;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial ObservableCollection<EventListItemDto> HighlightedEvents { get; set; } = new();

    [ObservableProperty]
    public partial ObservableCollection<EventListItemDto> OtherEvents { get; set; } = new();

    public HomeViewModel(IEventsApi eventsApi, IAuthService authService, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _authService = authService;
        _dialogs = dialogService;
    }

    [RelayCommand]
    private async Task LoadAsync()
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var result = await ApiResult.TryExecuteAsync(
                () => _eventsApi.GetAllAsync(page: 1, limit: 50, status: "opened"), "Home load");
            if (result is null)
            {
                await _dialogs.ShowErrorAsync("Não foi possível carregar os eventos.");
                return;
            }
            var filtered = _authService.CurrentCachedUser?.IsAdult == false
                ? result.Data.Where(e => !e.IsAdultOnly)
                : result.Data;
            var scored = filtered.OrderByDescending(CalculateScore).ToList();
            HighlightedEvents = new ObservableCollection<EventListItemDto>(scored.Take(5));
            OtherEvents = new ObservableCollection<EventListItemDto>(scored.Skip(5));
        }
        finally
        {
            IsLoading = false;
        }
    }

    private static int CalculateScore(EventListItemDto evt)
    {
        int score = 0;

        var daysUntilStart = (evt.StartDate - DateTime.UtcNow).TotalDays;
        if (daysUntilStart is >= 0 and <= 60)
            score += (int)(60 - daysUntilStart);

        score += Math.Min(evt.MaxParticipants / 10, 30);

        score += evt.LocationType switch
        {
            "hybrid" => 20,
            "in_person" => 15,
            "online" => 5,
            _ => 10
        };

        if ((evt.EndDate - evt.StartDate).TotalDays >= 1)
            score += 10;

        return score;
    }

    [RelayCommand]
    private async Task SelectEventAsync(EventListItemDto? eventItem)
    {
        if (eventItem is null) return;

        await Shell.Current.GoToAsync(nameof(Views.EventDetail), new Dictionary<string, object>
        {
            ["EventId"] = eventItem.Id
        });
    }
}
