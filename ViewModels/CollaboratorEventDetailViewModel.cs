using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EventId), "EventId")]
[QueryProperty(nameof(EventTitle), "EventTitle")]
[QueryProperty(nameof(EventDate), "EventDate")]
[QueryProperty(nameof(EventImage), "EventImage")]
[QueryProperty(nameof(EventRole), "EventRole")]
[QueryProperty(nameof(EventRoleColor), "EventRoleColor")]
[QueryProperty(nameof(EventRoleTextColor), "EventRoleTextColor")]
[QueryProperty(nameof(ParticipantCount), "ParticipantCount")]
public partial class CollaboratorEventDetailViewModel : ObservableObject
{
    [ObservableProperty]
    public partial string EventId { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventTitle { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventDate { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventImage { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventRole { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventRoleColor { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string EventRoleTextColor { get; set; } = string.Empty;

    [ObservableProperty]
    public partial int ParticipantCount { get; set; }

    [ObservableProperty]
    public partial bool IsCredenciamento { get; set; }

    [ObservableProperty]
    public partial string AccessNoteDescription { get; set; } = string.Empty;

    public CollaboratorEventDetailViewModel()
    {
    }

    partial void OnEventRoleChanged(string value)
    {
        IsCredenciamento = value == "CREDENCIAMENTO";
        AccessNoteDescription = value switch
        {
            "CREDENCIAMENTO" => "Você tem permissão para realizar o credenciamento dos participantes. Aproxime o QR Code do ingresso para validar a entrada.",
            "ORGANIZAÇÃO" => "Você tem acesso à lista completa de participantes e pode gerenciar a equipe do evento.",
            "PRODUÇÃO" => "Você tem acesso aos bastidores e à lista de participantes para coordenação logística.",
            _ => "Você tem acesso à lista de participantes do evento."
        };
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private async Task OpenParticipantListAsync()
    {
        await AppNavigation.ToParticipantsAsync(EventId, EventTitle);
    }

    [RelayCommand]
    private async Task OpenScannerAsync()
    {
        await AppNavigation.ToCheckInAsync(EventId);
    }
}
