using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventId), "EventId")]
public partial class ManageTicketsViewModel : ObservableObject
{
    private readonly ITicketTypesApi _ticketTypesApi;
    private readonly IEventsApi _eventsApi;
    private readonly IDialogService _dialogs;
    private TicketTypeViewModel? _editingTicketType;

    [ObservableProperty]
    public partial string EventId { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string NewName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string NewPrice { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string NewTotalQuantity { get; set; } = string.Empty;

    [ObservableProperty]
    public partial DateTime NewStartDate { get; set; } = DateTime.Today;

    [ObservableProperty]
    public partial DateTime NewEndDate { get; set; } = DateTime.Today.AddMonths(1);

    [ObservableProperty]
    public partial DateTime EventStartDate { get; set; }

    [ObservableProperty]
    public partial DateTime EventCreatedAt { get; set; }

    [ObservableProperty]
    public partial bool HasTickets { get; set; }

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial string? EditingTicketId { get; set; }

    public bool IsEditing => EditingTicketId is not null;
    public string FormTitle => IsEditing ? "Editar Ingresso" : "Novo Tipo de Ingresso";
    public string FormButtonText => IsEditing ? "Salvar" : "Adicionar";

    partial void OnEditingTicketIdChanged(string? value)
    {
        OnPropertyChanged(nameof(IsEditing));
        OnPropertyChanged(nameof(FormTitle));
        OnPropertyChanged(nameof(FormButtonText));
    }

    public ObservableCollection<TicketTypeViewModel> TicketTypes { get; } = new();

    public ManageTicketsViewModel(ITicketTypesApi ticketTypesApi, IEventsApi eventsApi, IDialogService dialogService)
    {
        _ticketTypesApi = ticketTypesApi;
        _eventsApi = eventsApi;
        _dialogs = dialogService;
    }

    partial void OnEventIdChanged(string value)
    {
        if (!string.IsNullOrEmpty(value))
            _ = LoadDataAsync();
    }

    private async Task LoadDataAsync()
    {
        if (IsLoading || string.IsNullOrEmpty(EventId)) return;
        IsLoading = true;

        try
        {
            var evt = (await ApiResult.TryExecuteAsync(() => _eventsApi.GetByIdAsync(EventId), "Load event"))?.Data;
            if (evt is not null)
            {
                EventCreatedAt = evt.CreatedAt?.ToLocalTime().Date ?? DateTime.Today;
                EventStartDate = evt.StartDate.ToLocalTime().Date;
                NewStartDate = EventCreatedAt;
                NewEndDate = EventStartDate;
            }

            var ticketResult = await ApiResult.TryExecuteAsync(
                    () => _ticketTypesApi.GetAllAsync(EventId, page: 1, limit: 100, availableOnly: false),
                    "Load ticket types")
                ?? new TicketTypeListPageDto(new List<TicketTypeDataDto>(), new TicketTypeListMeta(0, 0, 1, 100));
            var result = ticketResult;
            TicketTypes.Clear();
            foreach (var tt in result.Data)
                TicketTypes.Add(MapToPresentation(tt));
            HasTickets = TicketTypes.Count > 0;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"ManageTickets LoadDataAsync failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task SaveTicketTypeAsync()
    {
        if (string.IsNullOrWhiteSpace(NewName) ||
            string.IsNullOrWhiteSpace(NewPrice) ||
            string.IsNullOrWhiteSpace(NewTotalQuantity) ||
            string.IsNullOrEmpty(EventId))
            return;

        if (NewName.Trim().Length < 3)
        {
            await _dialogs.ShowErrorAsync("O nome do ingresso deve ter pelo menos 3 caracteres.");
            return;
        }

        if (!decimal.TryParse(NewPrice, out var price) || price < 0)
        {
            await _dialogs.ShowErrorAsync("Informe um preço válido (maior ou igual a zero).");
            return;
        }

        if (!int.TryParse(NewTotalQuantity, out var quantity) || quantity < 1)
        {
            await _dialogs.ShowErrorAsync("A quantidade total deve ser pelo menos 1.");
            return;
        }

        if (NewEndDate <= NewStartDate)
        {
            await _dialogs.ShowErrorAsync("A data de término deve ser posterior à data de início.");
            return;
        }

        if (NewStartDate < EventCreatedAt)
        {
            await _dialogs.ShowErrorAsync("A data de início deve ser a partir da criação do evento.");
            return;
        }

        if (NewEndDate > EventStartDate)
        {
            await _dialogs.ShowErrorAsync("A data de término não pode ultrapassar a data de início do evento.");
            return;
        }

        var overlap = TicketTypes.Any(tt =>
            tt.Id != EditingTicketId &&
            NewStartDate < tt.EndDate &&
            NewEndDate > tt.StartDate);

        if (overlap)
        {
            await _dialogs.ShowAlertAsync("Conflito de Período",
                "Já existe um tipo de ingresso cujo período sobrepõe este. Ajuste as datas.");
            return;
        }

        try
        {
            if (IsEditing && _editingTicketType is not null)
            {
                var updateDto = new UpdateTicketTypeDto(NewName.Trim(), price, quantity, NewStartDate, NewEndDate);
                var updated = await ApiResult.TryExecuteAsync(
                    () => _ticketTypesApi.UpdateAsync(_editingTicketType.Id, updateDto), "Update ticket type");
                if (updated is null)
                {
                    await _dialogs.ShowErrorAsync("Falha ao salvar ingresso.");
                    return;
                }

                _editingTicketType.Name = NewName.Trim();
                _editingTicketType.Price = price;
                _editingTicketType.TotalQuantity = quantity;
                _editingTicketType.StartDate = NewStartDate;
                _editingTicketType.EndDate = NewEndDate;
            }
            else
            {
                var dto = new CreateTicketTypeDto(NewName.Trim(), price, quantity, NewStartDate, NewEndDate);
                var result = (await ApiResult.TryExecuteAsync(() => _ticketTypesApi.CreateAsync(EventId, dto), "Create ticket type"))?.Data;
                if (result is null) return;

                TicketTypes.Add(MapToPresentation(result));
                HasTickets = true;
            }

            ResetForm();
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"Falha ao salvar ingresso: {ex.Message}");
        }
    }

    [RelayCommand]
    private async Task DeleteTicketTypeAsync(TicketTypeViewModel ticketType)
    {
        try
        {
            var deleted = await ApiResult.TryExecuteAsync(() => _ticketTypesApi.DeleteAsync(ticketType.Id), "Delete ticket type");
            if (!deleted)
            {
                await _dialogs.ShowErrorAsync("Não foi possível excluir o ingresso.");
                return;
            }
            TicketTypes.Remove(ticketType);

            if (_editingTicketType?.Id == ticketType.Id)
                CancelEdit();

            HasTickets = TicketTypes.Count > 0;
        }
        catch (Exception ex)
        {
            await _dialogs.ShowErrorAsync($"ManageTickets DeleteTicketTypeAsync failed: {ex.Message}");
        }
    }

    [RelayCommand]
    private void EditTicketType(TicketTypeViewModel ticketType)
    {
        _editingTicketType = ticketType;
        EditingTicketId = ticketType.Id;
        NewName = ticketType.Name;
        NewPrice = ticketType.Price.ToString("F2");
        NewTotalQuantity = ticketType.TotalQuantity.ToString();
        NewStartDate = ticketType.StartDate;
        NewEndDate = ticketType.EndDate;
    }

    [RelayCommand]
    private void CancelEdit()
    {
        ResetForm();
    }

    private void ResetForm()
    {
        _editingTicketType = null;
        EditingTicketId = null;
        NewName = string.Empty;
        NewPrice = string.Empty;
        NewTotalQuantity = string.Empty;
        NewStartDate = EventCreatedAt != default ? EventCreatedAt : DateTime.Today;
        NewEndDate = EventStartDate != default ? EventStartDate : DateTime.Today.AddMonths(1);
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    private static TicketTypeViewModel MapToPresentation(TicketTypeDataDto dto) => new()
    {
        Id = dto.Id,
        Name = dto.Name,
        Price = dto.Price,
        TotalQuantity = dto.TotalQuantity,
        AvailableQuantity = dto.AvailableQuantity,
        StartDate = dto.StartDate.ToLocalTime(),
        EndDate = dto.EndDate.ToLocalTime()
    };
}

public partial class TicketTypeViewModel : ObservableObject
{
    [ObservableProperty]
    public partial string Id { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Name { get; set; } = string.Empty;

    [ObservableProperty]
    public partial decimal Price { get; set; }

    [ObservableProperty]
    public partial int TotalQuantity { get; set; }

    [ObservableProperty]
    public partial int AvailableQuantity { get; set; }

    [ObservableProperty]
    public partial DateTime StartDate { get; set; }

    [ObservableProperty]
    public partial DateTime EndDate { get; set; }

    public string FormattedPrice => $"R$ {Price:F2}";
    public string AvailableLabel => $"{AvailableQuantity} ingressos disponíveis";
    public string FormattedPeriod => $"{StartDate:dd/MM/yyyy} – {EndDate:dd/MM/yyyy}";
}
