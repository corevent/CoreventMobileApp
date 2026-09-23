using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.Views;

namespace CoreventApp.ViewModels;

public partial class FavoritesViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly FavoritesService _favoritesService;
    private readonly IAuthService _authService;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsRefreshing { get; set; }

    public ObservableCollection<EventListItemDto> FavoriteEvents { get; } = new();

    public FavoritesViewModel(IEventsApi eventsApi, FavoritesService favoritesService, IAuthService authService)
    {
        _eventsApi = eventsApi;
        _favoritesService = favoritesService;
        _authService = authService;
    }

    private async Task<List<EventListItemDto>> LoadFavoriteEventsAsync()
    {
        var statuses = new[] { "opened", "going", "finished" };
        var tasks = statuses.Select(status =>
            ApiResult.TryExecuteAsync(
                () => _eventsApi.GetMyFavoriteEventsAsync(page: 1, limit: 100, status: status),
                "Load favorites"));
        var results = await Task.WhenAll(tasks);
        return results.Where(r => r is not null).SelectMany(r => r!.Data).ToList();
    }

    [RelayCommand]
    private async Task LoadFavoritesAsync()
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var events = await LoadFavoriteEventsAsync();
            var filtered = _authService.CurrentCachedUser?.IsAdult == false
                ? events.Where(e => !e.IsAdultOnly).ToList()
                : events;
            FavoriteEvents.Clear();
            foreach (var item in filtered)
                FavoriteEvents.Add(item);

            _favoritesService.SetFavorites(filtered);
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        IsRefreshing = true;

        try
        {
            var events = await LoadFavoriteEventsAsync();
            var filtered = _authService.CurrentCachedUser?.IsAdult == false
                ? events.Where(e => !e.IsAdultOnly).ToList()
                : events;
            FavoriteEvents.Clear();
            foreach (var item in filtered)
                FavoriteEvents.Add(item);

            _favoritesService.SetFavorites(filtered);
        }
        finally
        {
            IsRefreshing = false;
        }
    }

    [RelayCommand]
    private async Task SelectEventAsync(EventListItemDto? eventItem)
    {
        if (eventItem is null) return;

        await AppNavigation.ToEventAsync(eventItem.Id);
    }

    [RelayCommand]
    private async Task GoBack()
    {
        await Shell.Current.GoToAsync("..");
    }
}
