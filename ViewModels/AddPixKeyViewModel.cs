using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Helpers;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class AddPixKeyViewModel : ObservableObject
{
    private readonly PaymentInfoService _paymentInfoService;
    private readonly IDialogService _dialogs;

    private static readonly Dictionary<string, string> UiToApiPixType = new()
    {
        ["Email"] = "email",
        ["CPF"] = "cpf",
        ["CNPJ"] = "cnpj",
        ["Telefone"] = "phone",
        ["Chave Aleatória"] = "random"
    };

    public AddPixKeyViewModel(PaymentInfoService paymentInfoService, IDialogService dialogService)
    {
        _paymentInfoService = paymentInfoService;
        _dialogs = dialogService;
        SelectedKeyType = KeyTypes[0];
    }

    [ObservableProperty]
    public partial string Description { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string SelectedKeyType { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string KeyValue { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    public ObservableCollection<string> KeyTypes { get; } = new()
    {
        "Email",
        "CPF",
        "CNPJ",
        "Telefone",
        "Chave Aleatória"
    };

    [RelayCommand]
    private async Task SaveAsync()
    {
        if (string.IsNullOrWhiteSpace(Description))
        {
            await _dialogs.ShowErrorAsync("A descrição é obrigatória.");
            return;
        }

        if (string.IsNullOrWhiteSpace(KeyValue))
        {
            await _dialogs.ShowErrorAsync("Por favor, informe a chave Pix.");
            return;
        }

        bool isValid = true;
        string errorMessage = "";

        switch (SelectedKeyType)
        {
            case "Email":
                if (!ValidationHelper.IsValidEmail(KeyValue))
                {
                    isValid = false;
                    errorMessage = "E-mail inválido.";
                }
                break;
            case "CPF":
                if (!ValidationHelper.IsValidCpf(KeyValue))
                {
                    isValid = false;
                    errorMessage = "CPF inválido.";
                }
                break;
            case "Telefone":
                if (!ValidationHelper.IsValidPhone(KeyValue))
                {
                    isValid = false;
                    errorMessage = "Telefone inválido.";
                }
                break;
        }

        if (!isValid)
        {
            await _dialogs.ShowErrorAsync(errorMessage);
            return;
        }

        var pixType = UiToApiPixType.GetValueOrDefault(SelectedKeyType);

        var dto = new CreateOrganizerPaymentInfoDto(
            Description,
            null,
            null,
            null,
            null,
            KeyValue,
            pixType,
            null);

        IsLoading = true;
        var result = await _paymentInfoService.CreateAsync(dto);
        IsLoading = false;

        if (result != null)
            await Shell.Current.GoToAsync("..");
        else
            await _dialogs.ShowErrorAsync("Não foi possível salvar a chave Pix. Tente novamente.");
    }

    [RelayCommand]
    private async Task CancelAsync()
    {
        await Shell.Current.GoToAsync("..");
    }
}
