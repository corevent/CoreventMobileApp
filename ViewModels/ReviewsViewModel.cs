using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public partial class ReviewsViewModel : ObservableObject
{
    private readonly IEventRatingsApi _ratingsApi;

    public ReviewsViewModel(IEventRatingsApi ratingsApi)
    {
        _ratingsApi = ratingsApi;
    }

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsEmpty { get; set; }

    [ObservableProperty]
    public partial bool IsRefreshing { get; set; }

    public ObservableCollection<MyRatingItemDto> Items { get; } = [];

    [RelayCommand]
    public async Task LoadItems()
    {
        IsLoading = true;

        var result = await ApiResult.TryExecuteAsync(() => _ratingsApi.GetMyRatingsAsync(page: 1, limit: 100), "Load ratings")
            ?? new MyRatingsListPageDto(new List<MyRatingItemDto>(), new PaginationMetaDto(0, 0, 1, 100));

        Items.Clear();
        foreach (var item in result.Data)
            Items.Add(item);

        IsEmpty = Items.Count == 0;
        IsLoading = false;
    }

    [RelayCommand]
    private async Task Refresh()
    {
        var result = await ApiResult.TryExecuteAsync(() => _ratingsApi.GetMyRatingsAsync(page: 1, limit: 100), "Refresh ratings")
            ?? new MyRatingsListPageDto(new List<MyRatingItemDto>(), new PaginationMetaDto(0, 0, 1, 100));

        Items.Clear();
        foreach (var item in result.Data)
            Items.Add(item);

        IsEmpty = Items.Count == 0;
        IsRefreshing = false;
    }

    [RelayCommand]
    private async Task GoBack()
    {
        await Shell.Current.GoToAsync("..");
    }
}
