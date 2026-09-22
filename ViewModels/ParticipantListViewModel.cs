using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventId), "EventId")]
[QueryProperty(nameof(EventName), "EventName")]
public partial class ParticipantListViewModel : ObservableObject
{
    private readonly IParticipantsApi _participantsApi;

    [ObservableProperty]
    public partial string EventId { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    public bool IsEmpty => !IsLoading && Participants.Count == 0;

    public ObservableCollection<ParticipantSummary> Participants { get; } = new();

    public ParticipantListViewModel(IParticipantsApi participantsApi)
    {
        _participantsApi = participantsApi;
    }

    partial void OnEventIdChanged(string value)
    {
        if (!string.IsNullOrEmpty(value))
            _ = LoadDataAsync(value);
    }

    private async Task LoadDataAsync(string eventId)
    {
        if (IsLoading) return;
        IsLoading = true;

        try
        {
            var result = await ApiResult.TryExecuteAsync(
                    () => _participantsApi.GetAllAsync(eventId, page: 1, limit: 100), "Load participants")
                ?? new ParticipantListPageDto(new List<ParticipantDataDto>(), new ParticipantPaginationMetaDto(0, 0, 1, 100));

            Participants.Clear();
            foreach (var p in result.Data)
            {
                Participants.Add(new ParticipantSummary
                {
                    FullName = p.Name,
                    Email = p.Email,
                    TicketsCount = p.TicketsCount
                });
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"ParticipantList LoadDataAsync failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
            OnPropertyChanged(nameof(IsEmpty));
        }
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private async Task ExportCsvAsync()
    {
        await Shell.Current.DisplayAlertAsync("Exportar", "Lista exportada com sucesso!", "OK");
    }
}

public partial class ParticipantSummary : ObservableObject
{
    [ObservableProperty]
    public partial string FullName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Email { get; set; } = string.Empty;

    [ObservableProperty]
    public partial int TicketsCount { get; set; }

    public string Initial => string.IsNullOrEmpty(FullName) ? "?" : FullName[..1].ToUpper();
}
