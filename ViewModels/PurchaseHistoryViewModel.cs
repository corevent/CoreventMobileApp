using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public partial class PurchaseHistoryViewModel : ObservableObject
{
    private readonly IOrdersApi _ordersApi;

    public PurchaseHistoryViewModel(IOrdersApi ordersApi)
    {
        _ordersApi = ordersApi;
    }

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsEmpty { get; set; }

    public ObservableCollection<MyOrdersDataDto> Orders { get; } = [];

    [RelayCommand]
    public async Task LoadOrders()
    {
        IsLoading = true;

        var result = await ApiResult.TryExecuteAsync(() => _ordersApi.GetMyOrdersAsync(page: 1, limit: 50), "Load orders")
            ?? new PaginateMyOrdersDto(new List<MyOrdersDataDto>(), new PaginationMetaDto(0, 0, 1, 50));

        Orders.Clear();
        foreach (var order in result.Data)
            Orders.Add(order);

        IsEmpty = Orders.Count == 0;
        IsLoading = false;
    }

    [RelayCommand]
    private async Task OpenOrderDetail(MyOrdersDataDto? order)
    {
        if (order is null) return;

        await Shell.Current.GoToAsync(nameof(Views.OrderDetailPage), new Dictionary<string, object>
        {
            [nameof(OrderDetailViewModel.OrderId)] = order.Id
        });
    }

    [RelayCommand]
    private async Task GoBack()
    {
        await Shell.Current.GoToAsync("..");
    }
}
