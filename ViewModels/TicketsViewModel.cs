using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

public partial class TicketsViewModel : ObservableObject
{
    private readonly ITicketsApi _ticketsApi;

    public TicketsViewModel(ITicketsApi ticketsApi)
    {
        _ticketsApi = ticketsApi;
    }

    [ObservableProperty]
    public partial bool IsProximosVisible { get; set; } = true;

    [ObservableProperty]
    public partial bool IsPassadosVisible { get; set; } = false;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsEmptyProximos { get; set; }

    [ObservableProperty]
    public partial bool IsEmptyPassados { get; set; }

    public ObservableCollection<UserTicketDataDto> ProximosTickets { get; } = [];
    public ObservableCollection<UserTicketDataDto> PassadosTickets { get; } = [];

    [RelayCommand]
    public async Task LoadTickets()
    {
        IsLoading = true;

        var result = await ApiResult.TryExecuteAsync(() => _ticketsApi.GetMyTicketsAsync(page: 1, limit: 100), "Load tickets")
            ?? new PaginateMyTicketsDto(new List<UserTicketDataDto>(), new PaginationMetaDto(0, 0, 1, 100));

        ProximosTickets.Clear();
        PassadosTickets.Clear();

        foreach (var ticket in result.Data)
        {
            if (ticket.Status is "pending" or "paid")
                ProximosTickets.Add(ticket);
            else
                PassadosTickets.Add(ticket);
        }

        IsEmptyProximos = ProximosTickets.Count == 0;
        IsEmptyPassados = PassadosTickets.Count == 0;
        IsLoading = false;
    }

    [RelayCommand]
    public void SelectProximos()
    {
        IsProximosVisible = true;
        IsPassadosVisible = false;
    }

    [RelayCommand]
    public void SelectPassados()
    {
        IsProximosVisible = false;
        IsPassadosVisible = true;
    }

    [RelayCommand]
    private async Task OpenTicketQrCode(UserTicketDataDto? ticket)
    {
        if (ticket is null) return;

        await Shell.Current.GoToAsync(nameof(Views.TicketQrCodePage), new Dictionary<string, object>
        {
            [nameof(TicketQrCodeViewModel.TicketId)] = ticket.Id,
            [nameof(TicketQrCodeViewModel.QrToken)] = ticket.QrToken,
            [nameof(TicketQrCodeViewModel.EventTitle)] = ticket.Event.Title,
            [nameof(TicketQrCodeViewModel.TicketTypeName)] = ticket.TicketType.Name,
            [nameof(TicketQrCodeViewModel.Price)] = ticket.TicketType.Price,
            [nameof(TicketQrCodeViewModel.Status)] = ticket.Status,
            [nameof(TicketQrCodeViewModel.OrderId)] = ticket.Order.Id
        });
    }
}
