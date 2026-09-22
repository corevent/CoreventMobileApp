using System.Collections.Concurrent;
using System.Collections.ObjectModel;
using System.Text.Json;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventId), "EventId")]
public partial class EventDetailViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly IAttractionsApi _attractionsApi;
    private readonly FavoritesService _favoritesService;
    private readonly IEventRatingsApi _ratingsApi;
    private readonly IDialogService _dialogs;
    private readonly ConcurrentDictionary<string, (int Rating, string RatingId)> _ratingCache = new();
    private string? _eventId;

    [ObservableProperty]
    public partial string EventName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Category { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventDate { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Location { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string ImageUrl { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string OrganizerName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string OrganizerAvatar { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Price { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsFavorite { get; set; }

    [ObservableProperty]
    public partial string OnlineUrl { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string LocationTypeDisplay { get; set; } = "Presencial";

    [ObservableProperty]
    public partial string Description { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsAdultOnlyVisible { get; set; }

    [ObservableProperty]
    public partial bool IsPhysicalLocation { get; set; } = true;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool HasAttractions { get; set; }

    [ObservableProperty]
    public partial double AverageRating { get; set; }

    [ObservableProperty]
    public partial int UserRating { get; set; }

    public bool HasDescription => !string.IsNullOrWhiteSpace(Description);
    public bool HasAverageRating => AverageRating > 0;
    public string AverageRatingDisplay => HasAverageRating ? AverageRating.ToString("F1") : "";
    public bool HasRated => UserRating > 0;

    public bool Star1Filled => UserRating >= 1;
    public bool Star2Filled => UserRating >= 2;
    public bool Star3Filled => UserRating >= 3;
    public bool Star4Filled => UserRating >= 4;
    public bool Star5Filled => UserRating >= 5;

    partial void OnDescriptionChanged(string value) => OnPropertyChanged(nameof(HasDescription));

    partial void OnLocationTypeDisplayChanged(string value) => OnPropertyChanged(nameof(IsPhysicalLocation));

    partial void OnAverageRatingChanged(double value)
    {
        OnPropertyChanged(nameof(HasAverageRating));
        OnPropertyChanged(nameof(AverageRatingDisplay));
    }

    partial void OnUserRatingChanged(int value)
    {
        OnPropertyChanged(nameof(HasRated));
        OnPropertyChanged(nameof(Star1Filled));
        OnPropertyChanged(nameof(Star2Filled));
        OnPropertyChanged(nameof(Star3Filled));
        OnPropertyChanged(nameof(Star4Filled));
        OnPropertyChanged(nameof(Star5Filled));
    }

    public string? EventId
    {
        set
        {
            _eventId = value;
            if (value is not null) _ = LoadEventAsync(value);
        }
    }

    public ObservableCollection<AttractionDto> Attractions { get; } = new();

    public EventDetailViewModel(IEventsApi eventsApi, IAttractionsApi attractionsApi, FavoritesService favoritesService, IEventRatingsApi ratingsApi, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _attractionsApi = attractionsApi;
        _favoritesService = favoritesService;
        _ratingsApi = ratingsApi;
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

            EventName = evt.Title;
            EventDate = $"{evt.StartDate.ToLocalTime():dd MMM, yyyy} • {evt.StartDate.ToLocalTime():HH:mm} - {evt.EndDate.ToLocalTime():HH:mm}";
            ImageUrl = evt.BannerUrl ?? string.Empty;
            Category = evt.Category;
            Description = evt.Description ?? string.Empty;
            IsAdultOnlyVisible = evt.IsAdultOnly;
            IsPhysicalLocation = evt.LocationType != "online";
            AverageRating = evt.AverageRating ?? 0;
            UserRating = LoadUserRatingFromCache(eventId);

            var cityPart = !string.IsNullOrEmpty(evt.CityName) ? $", {evt.CityName}" : "";
            if (!string.IsNullOrEmpty(evt.StateAcronym))
                cityPart += $" - {evt.StateAcronym}";
            Location = $"{evt.LocationName}{cityPart}";

            OrganizerName = evt.Organizer.Name ?? string.Empty;
            OrganizerAvatar = evt.Organizer.AvatarUrl ?? "profile_default_icon.png";
            OnlineUrl = evt.LocationType == "online" ? evt.LocationName : string.Empty;
            LocationTypeDisplay = evt.LocationType switch
            {
                "online" => "Online",
                "in_person" => "Presencial",
                "hybrid" => "Híbrido",
                _ => "Presencial"
            };

            IsFavorite = _favoritesService.IsFavorite(eventId);

            _ = LoadAttractionsAsync(eventId);
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"EventDetail LoadEventAsync failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
        }
    }

    private async Task LoadAttractionsAsync(string eventId)
    {
        try
        {
            var result = await ApiResult.TryExecuteAsync(() => _attractionsApi.GetAllAsync(eventId), "Load attractions")
                ?? throw new InvalidOperationException("Load attractions failed.");
            Attractions.Clear();
            foreach (var item in result.Data)
                Attractions.Add(item with
                {
                    StartDate = item.StartDate.ToLocalTime(),
                    EndDate = item.EndDate.ToLocalTime()
                });
            HasAttractions = Attractions.Count > 0;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"EventDetail LoadAttractionsAsync failed: {ex.Message}");
        }
    }

    [RelayCommand]
    private async Task GoBack()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private async Task ToggleFavorite()
    {
        if (_eventId is null) return;

        if (IsFavorite)
        {
            var removed = await _favoritesService.RemoveFavoriteAsync(_eventId);
            if (removed) IsFavorite = false;
        }
        else
        {
            var result = await _favoritesService.AddFavoriteAsync(_eventId);
            if (result is not null) IsFavorite = true;
        }
    }

    [RelayCommand]
    private async Task ShareEvent()
    {
        await Share.Default.RequestAsync(new ShareTextRequest
        {
            Title = EventName,
            Text = $"Confira o evento: {EventName}"
        });
    }

    [RelayCommand]
    private async Task BuyTicket()
    {
        if (_eventId is null) return;
        await Shell.Current.GoToAsync($"{nameof(Views.CheckoutPage)}?EventId={_eventId}");
    }

    [RelayCommand]
    private async Task SetRating(string? stars)
    {
        if (_eventId is null) return;
        if (stars is null || !int.TryParse(stars, out var rating) || rating < 1 || rating > 5) return;

        try
        {
            var cached = GetCachedRating(_eventId);
            if (cached is null)
            {
                var response = await ApiResult.TryExecuteAsync(
                    () => _ratingsApi.CreateAsync(_eventId, new CreateEventRatingDto(rating)), "Create rating");
                if (response is null)
                {
                    await _dialogs.ShowErrorAsync("Falha ao avaliar. Tente novamente.");
                    return;
                }
                SaveRatingToCache(_eventId, rating, response.Data.Id);
                UserRating = rating;
            }
            else if (cached.Value.Rating == rating)
            {
                var deleted = await ApiResult.TryExecuteAsync(
                    () => _ratingsApi.DeleteAsync(cached.Value.RatingId), "Delete rating");
                if (!deleted)
                {
                    await _dialogs.ShowErrorAsync("Falha ao avaliar. Tente novamente.");
                    return;
                }
                RemoveRatingFromCache(_eventId);
                UserRating = 0;
            }
            else
            {
                var updated = await ApiResult.TryExecuteAsync(
                    () => _ratingsApi.UpdateAsync(cached.Value.RatingId, new CreateEventRatingDto(rating)), "Update rating");
                if (!updated)
                {
                    await _dialogs.ShowErrorAsync("Falha ao avaliar. Tente novamente.");
                    return;
                }
                SaveRatingToCache(_eventId, rating, cached.Value.RatingId);
                UserRating = rating;
            }
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"Falha ao avaliar: {ex.Message}");
        }
    }

    private record RatingCacheData(int Rating, string RatingId);

    private (int Rating, string RatingId)? GetCachedRating(string eventId)
    {
        if (_ratingCache.TryGetValue(eventId, out var cached))
            return cached;

        var json = Preferences.Get($"rating_{eventId}", null);
        if (json is not null)
        {
            try
            {
                var data = JsonSerializer.Deserialize<RatingCacheData>(json, JsonConfig.Options);
                if (data is not null)
                {
                    _ratingCache[eventId] = (data.Rating, data.RatingId);
                    return (data.Rating, data.RatingId);
                }
            }
            catch { }
        }
        return null;
    }

    private void SaveRatingToCache(string eventId, int rating, string ratingId)
    {
        _ratingCache[eventId] = (rating, ratingId);
        var json = JsonSerializer.Serialize(new RatingCacheData(rating, ratingId), JsonConfig.Options);
        Preferences.Set($"rating_{eventId}", json);
    }

    private void RemoveRatingFromCache(string eventId)
    {
        _ratingCache.TryRemove(eventId, out _);
        Preferences.Remove($"rating_{eventId}");
    }

    private int LoadUserRatingFromCache(string eventId)
    {
        var cached = GetCachedRating(eventId);
        return cached?.Rating ?? 0;
    }
}
