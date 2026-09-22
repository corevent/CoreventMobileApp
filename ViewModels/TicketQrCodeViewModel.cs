using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using QRCoder;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(TicketId), "TicketId")]
[QueryProperty(nameof(QrToken), "QrToken")]
[QueryProperty(nameof(EventTitle), "EventTitle")]
[QueryProperty(nameof(TicketTypeName), "TicketTypeName")]
[QueryProperty(nameof(Price), "Price")]
[QueryProperty(nameof(Status), "Status")]
[QueryProperty(nameof(OrderId), "OrderId")]
public partial class TicketQrCodeViewModel : ObservableObject
{
    [ObservableProperty]
    public partial string TicketId { get; set; } = string.Empty;

    private string? _qrToken;

    public string? QrToken
    {
        get => _qrToken;
        set
        {
            if (SetProperty(ref _qrToken, value) && value is not null)
                GenerateQrCode(value);
        }
    }

    [ObservableProperty]
    public partial string EventTitle { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string TicketTypeName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial decimal Price { get; set; }

    [ObservableProperty]
    public partial string Status { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string OrderId { get; set; } = string.Empty;

    [ObservableProperty]
    public partial ImageSource? QrCodeSource { get; set; }

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    private void GenerateQrCode(string qrToken)
    {
        if (string.IsNullOrEmpty(qrToken)) return;

        try
        {
            IsLoading = true;
            var generator = new QRCodeGenerator();
            var qrData = generator.CreateQrCode(qrToken, QRCodeGenerator.ECCLevel.Q);
            var qrCode = new PngByteQRCode(qrData);
            var bytes = qrCode.GetGraphic(20);
            QrCodeSource = ImageSource.FromStream(() => new MemoryStream(bytes));
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"QR code generation failed: {ex.Message}");
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task GoBack()
    {
        await Shell.Current.GoToAsync("..");
    }
}
