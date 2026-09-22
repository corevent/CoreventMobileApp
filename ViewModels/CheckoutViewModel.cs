using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventId), "EventId")]
public partial class CheckoutViewModel : ObservableObject
{
    private readonly IEventsApi _eventsApi;
    private readonly ITicketTypesApi _ticketTypesApi;
    private readonly IOrdersApi _ordersApi;
    private readonly IAgePoliciesApi _agePolicyApi;
    private string? _eventId;
    private string? _orderId;
    private string? _checkoutUrl;

    [ObservableProperty]
    public partial string EventName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventDate { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventImageUrl { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool IsPurchasing { get; set; }

    [ObservableProperty]
    public partial bool IsAdultOnly { get; set; }

    public string? EventId
    {
        set
        {
            _eventId = value;
            if (value is not null) _ = LoadDataAsync(value);
        }
    }

    public ObservableCollection<SelectableTicketType> TicketTypes { get; } = new();

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(Subtotal))]
    [NotifyPropertyChangedFor(nameof(Total))]
    [NotifyPropertyChangedFor(nameof(ButtonText))]
    [NotifyPropertyChangedFor(nameof(HasReachedMaxQuantity))]
    [NotifyPropertyChangedFor(nameof(HasMinQuantity))]
    public partial SelectableTicketType? SelectedTicketType { get; set; }

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(Subtotal))]
    [NotifyPropertyChangedFor(nameof(Total))]
    [NotifyPropertyChangedFor(nameof(ButtonText))]
    [NotifyPropertyChangedFor(nameof(HasReachedMaxQuantity))]
    [NotifyPropertyChangedFor(nameof(HasMinQuantity))]
    public partial int Quantity { get; set; } = 1;

    public decimal Subtotal => SelectedTicketType?.TicketType.Price * Quantity ?? 0;
    public decimal Total => Subtotal;

    public bool HasMinQuantity => Quantity <= 1;
    public bool HasReachedMaxQuantity => SelectedTicketType != null && Quantity >= SelectedTicketType.TicketType.AvailableQuantity;

    public string ButtonText => IsPurchasing ? "" : $"Finalizar Compra • R$ {Total:F2}";

    public CheckoutViewModel(IEventsApi eventsApi, ITicketTypesApi ticketTypesApi, IOrdersApi ordersApi, IAgePoliciesApi agePolicyApi)
    {
        _eventsApi = eventsApi;
        _ticketTypesApi = ticketTypesApi;
        _ordersApi = ordersApi;
        _agePolicyApi = agePolicyApi;
    }

    private async Task LoadDataAsync(string eventId)
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var evt = (await ApiResult.TryExecuteAsync(() => _eventsApi.GetByIdAsync(eventId), "Load event"))?.Data;
            if (evt is null) return;

            EventName = evt.Title;
            EventDate = $"{evt.StartDate.ToLocalTime():dd MMM, yyyy • HH:mm}";
            EventImageUrl = evt.BannerUrl ?? string.Empty;
            IsAdultOnly = evt.IsAdultOnly;

            var ticketResult = await ApiResult.TryExecuteAsync(
                    () => _ticketTypesApi.GetAllAsync(eventId, availableOnly: true), "Load ticket types")
                ?? new TicketTypeListPageDto(new List<TicketTypeDataDto>(), new TicketTypeListMeta(0, 0, 1, 20));
            TicketTypes.Clear();
            foreach (var tt in ticketResult.Data)
            {
                var wrapped = new SelectableTicketType(tt);
                TicketTypes.Add(wrapped);
            }

            if (TicketTypes.Count > 0)
            {
                var first = TicketTypes[0];
                first.IsSelected = true;
                SelectedTicketType = first;
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Checkout LoadDataAsync failed: {ex.Message}");
            await Shell.Current.DisplayAlertAsync("Erro", "Não foi possível carregar os dados do checkout.", "OK");
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private void SelectTicketType(SelectableTicketType ticketType)
    {
        if (SelectedTicketType is not null)
            SelectedTicketType.IsSelected = false;

        ticketType.IsSelected = true;
        SelectedTicketType = ticketType;
        Quantity = 1;
    }

    [RelayCommand]
    private void IncreaseQuantity()
    {
        if (SelectedTicketType is not null && Quantity < SelectedTicketType.TicketType.AvailableQuantity)
            Quantity++;
    }

    [RelayCommand]
    private void DecreaseQuantity()
    {
        if (Quantity > 1)
            Quantity--;
    }

    [RelayCommand]
    private async Task FinalizePurchaseAsync()
    {
        if (IsPurchasing || _eventId is null || SelectedTicketType is null) return;
        IsPurchasing = true;

        try
        {
            var dto = new CreateOrderDto(new List<ItemsDto>
            {
                new(SelectedTicketType.TicketType.Id, Quantity)
            });

            var result = (await ApiResult.TryExecuteAsync(() => _ordersApi.CreateAsync(_eventId, dto), "Create order"))?.Data;
            if (result is null)
            {
                await Shell.Current.DisplayAlertAsync("Erro", "Não foi possível finalizar a compra. Tente novamente.", "OK");
                return;
            }
            _orderId = result.OrderId;
            _checkoutUrl = result.CheckoutLinks?.FirstOrDefault(l => l.Rel == "PAY")?.Href;

            if (IsAdultOnly)
            {
                var acceptance = await ApiResult.TryExecuteAsync(() => _agePolicyApi.CheckAcceptanceAsync(), "Check age policy");
                var hasAccepted = acceptance?.Data.UserHasAccepted ?? false;
                if (!hasAccepted)
                {
                    var policy = (await ApiResult.TryExecuteAsync(() => _agePolicyApi.GetActivePolicyAsync(), "Load age policy"))?.Data;
                    if (policy is not null)
                    {
                        var consent = await Shell.Current.DisplayAlertAsync(
                            "Aviso de Conteúdo +18",
                            policy.Description,
                            "Estou ciente",
                            "Cancelar");
                        if (!consent) return;
                        await ApiResult.TryExecuteAsync(() => _agePolicyApi.AcceptPolicyAsync(), "Accept age policy");
                    }
                }
            }

            if (!string.IsNullOrEmpty(_checkoutUrl))
            {
                await Shell.Current.DisplayAlertAsync("Pagamento",
                    "Você será redirecionado ao PagBank para finalizar o pagamento.", "OK");
                await Browser.Default.OpenAsync(_checkoutUrl, BrowserLaunchMode.SystemPreferred);
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Checkout FinalizePurchaseAsync failed: {ex.Message}");
            await Shell.Current.DisplayAlertAsync("Erro", "Não foi possível finalizar a compra. Tente novamente.", "OK");
        }
        finally
        {
            IsPurchasing = false;
        }
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }
}