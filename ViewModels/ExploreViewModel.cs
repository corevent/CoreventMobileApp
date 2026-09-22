using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public partial class CategoryItem : ObservableObject
{
    [ObservableProperty]
    public partial string Name { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string ApiValue { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsSelected { get; set; }
}

public partial class ExploreViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly IAuthService _authService;
    private readonly IDialogService _dialogs;
    private int _currentPage = 1;
    private const int PageSize = 10;
    private bool _hasMorePages = true;
    private CancellationTokenSource? _debounceCts;
    private const int DebounceDelayMs = 400;

    [ObservableProperty]
    public partial string SearchText { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsLoadingMore { get; set; }

    public ObservableCollection<CategoryItem> Categories { get; } = new();
    public ObservableCollection<EventListItemDto> Events { get; } = new();

    public ExploreViewModel(IEventsApi eventsApi, IAuthService authService, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _authService = authService;
        _dialogs = dialogService;

        Categories.Add(new CategoryItem { Name = "Todos", ApiValue = "", IsSelected = true });
        Categories.Add(new CategoryItem { Name = "Música", ApiValue = "music" });
        Categories.Add(new CategoryItem { Name = "Tecnologia", ApiValue = "tech" });
        Categories.Add(new CategoryItem { Name = "Gastronomia", ApiValue = "gastronomy" });
        Categories.Add(new CategoryItem { Name = "Arte e Cultura", ApiValue = "art_culture" });
        Categories.Add(new CategoryItem { Name = "Esportes", ApiValue = "sports" });
        Categories.Add(new CategoryItem { Name = "Educação", ApiValue = "education" });
        Categories.Add(new CategoryItem { Name = "Negócios", ApiValue = "business" });
        Categories.Add(new CategoryItem { Name = "Saúde e Bem-estar", ApiValue = "health_wellness" });
        Categories.Add(new CategoryItem { Name = "Família e Crianças", ApiValue = "family_kids" });
        Categories.Add(new CategoryItem { Name = "Religioso/Espiritual", ApiValue = "religious_spiritual" });
        Categories.Add(new CategoryItem { Name = "Jogos", ApiValue = "games" });
        Categories.Add(new CategoryItem { Name = "Comunidade/Social", ApiValue = "community_social" });
        Categories.Add(new CategoryItem { Name = "Moda e Beleza", ApiValue = "fashion_beauty" });
        Categories.Add(new CategoryItem { Name = "Outro", ApiValue = "other" });
    }

    partial void OnSearchTextChanged(string value)
    {
        _debounceCts?.Cancel();
        _debounceCts = new CancellationTokenSource();
        _ = DebounceSearchAsync(_debounceCts.Token);
    }

    private async Task DebounceSearchAsync(CancellationToken token)
    {
        try
        {
            await Task.Delay(DebounceDelayMs, token);
            if (!token.IsCancellationRequested)
                await SearchCommand.ExecuteAsync(null);
        }
        catch (OperationCanceledException)
        {
            // Expected on every keystroke: a newer search superseded this one.
        }
    }

    [RelayCommand]
    private async Task SearchAsync()
    {
        if (IsLoading) return;
        IsLoading = true;
        _currentPage = 1;
        _hasMorePages = true;

        try
        {
            var selected = GetSelectedCategoryApiValue();

            var result = await ApiResult.TryExecuteAsync(() => _eventsApi.GetAllAsync(
                page: _currentPage, limit: PageSize,
                search: string.IsNullOrWhiteSpace(SearchText) ? null : SearchText,
                category: selected,
                stateId: null,
                cityId: null,
                status: "opened"), "Explore search")
                ?? new EventListPageDto(new List<EventListItemDto>(), new PaginationMetaDto(0, 0, _currentPage, PageSize));

            var filtered = _authService.CurrentCachedUser?.IsAdult == false
                ? result.Data.Where(e => !e.IsAdultOnly)
                : result.Data;
            Events.Clear();
            foreach (var item in filtered)
                Events.Add(item);

            _hasMorePages = _currentPage < result.Meta.TotalPages;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"Explore SearchAsync failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task LoadMoreAsync()
    {
        if (IsLoadingMore || !_hasMorePages) return;
        IsLoadingMore = true;

        try
        {
            _currentPage++;
            var selected = GetSelectedCategoryApiValue();

            var result = await ApiResult.TryExecuteAsync(() => _eventsApi.GetAllAsync(
                page: _currentPage, limit: PageSize,
                search: string.IsNullOrWhiteSpace(SearchText) ? null : SearchText,
                category: selected,
                stateId: null,
                cityId: null,
                status: "opened"), "Explore load more")
                ?? new EventListPageDto(new List<EventListItemDto>(), new PaginationMetaDto(0, 0, _currentPage, PageSize));

            var filtered = _authService.CurrentCachedUser?.IsAdult == false
                ? result.Data.Where(e => !e.IsAdultOnly)
                : result.Data;
            foreach (var item in filtered)
                Events.Add(item);

            _hasMorePages = _currentPage < result.Meta.TotalPages;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"Explore LoadMoreAsync failed: {ex.Message}");
            _currentPage--;
        }
        finally
        {
            IsLoadingMore = false;
        }
    }

    [RelayCommand]
    private async Task SelectCategoryAsync(CategoryItem category)
    {
        foreach (var c in Categories)
            c.IsSelected = c == category;
        await SearchCommand.ExecuteAsync(null);
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

    private string? GetSelectedCategoryApiValue()
    {
        var selected = Categories.FirstOrDefault(c => c.IsSelected);
        return selected is not null && !string.IsNullOrEmpty(selected.ApiValue)
            ? selected.ApiValue
            : null;
    }
}
