using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(OrderId), "OrderId")]
public partial class OrderDetailViewModel : ObservableObject
{
    private readonly IOrdersApi _ordersApi;

    public OrderDetailViewModel(IOrdersApi ordersApi)
    {
        _ordersApi = ordersApi;
    }

    [ObservableProperty]
    public partial string OrderId { get; set; } = string.Empty;

    [ObservableProperty]
    public partial OrderDetailsDataDto? Order { get; set; }

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    public ObservableCollection<OrderTicketDto> Tickets { get; } = [];

    partial void OnOrderIdChanged(string value)
    {
        if (!string.IsNullOrWhiteSpace(value))
            _ = LoadOrderAsync(value);
    }

    private async Task LoadOrderAsync(string orderId)
    {
        IsLoading = true;

        var result = await ApiResult.TryExecuteAsync(() => _ordersApi.GetByIdAsync(orderId), "Load order");
        if (result is not null)
        {
            Order = result.Data;
            Tickets.Clear();
            foreach (var ticket in result.Data.Tickets)
                Tickets.Add(ticket);
        }

        IsLoading = false;
    }

    [RelayCommand]
    private async Task OpenTicketQrCode(OrderTicketDto? ticket)
    {
        if (ticket is null || Order is null) return;

        await Shell.Current.GoToAsync(nameof(Views.TicketQrCodePage), new Dictionary<string, object>
        {
            [nameof(TicketQrCodeViewModel.TicketId)] = ticket.Id,
            [nameof(TicketQrCodeViewModel.QrToken)] = ticket.QrToken,
            [nameof(TicketQrCodeViewModel.EventTitle)] = Order.Event.Title,
            [nameof(TicketQrCodeViewModel.TicketTypeName)] = ticket.TicketType.Name,
            [nameof(TicketQrCodeViewModel.Price)] = ticket.TicketType.Price,
            [nameof(TicketQrCodeViewModel.Status)] = ticket.Status,
            [nameof(TicketQrCodeViewModel.OrderId)] = Order.Id
        });
    }

    [RelayCommand]
    private async Task GoBack()
    {
        await Shell.Current.GoToAsync("..");
    }

    public static string StatusText(string status) => status switch
    {
        "paid" => "CONCLUÍDO",
        "pending" => "PENDENTE",
        "cancelled" => "CANCELADO",
        "checked_in" => "FINALIZADO",
        _ => status.ToUpperInvariant()
    };
}
