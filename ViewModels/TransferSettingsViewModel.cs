using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class BankAccountItem : ObservableObject
{
    [ObservableProperty]
    public partial string Id { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Description { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string BankCode { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string BranchNumber { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string BranchDigit { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string AccountNumber { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string AccountDigit { get; set; } = string.Empty;

    public string DisplayText =>
        $"{Description} • CÓD {BankCode} • AG {BranchNumber} • CONTA {AccountNumber}-{AccountDigit}";
}

public partial class PixKeyItem : ObservableObject
{
    private static readonly Dictionary<string, string> ApiToUiPixType = new()
    {
        ["email"] = "Email",
        ["cpf"] = "CPF",
        ["cnpj"] = "CNPJ",
        ["phone"] = "Telefone",
        ["random"] = "Chave Aleatória"
    };

    [ObservableProperty]
    public partial string Id { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Description { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Key { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Type { get; set; } = string.Empty;

    public static PixKeyItem FromApi(string id, string description, string pixKey, string? pixType) => new()
    {
        Id = id,
        Description = description,
        Key = pixKey,
        Type = pixType != null && ApiToUiPixType.TryGetValue(pixType, out var ui) ? ui : pixType ?? ""
    };
}

public partial class TransferSettingsViewModel : ObservableObject
{
    private readonly PaymentInfoService _paymentInfoService;
    private readonly IDialogService _dialogs;

    public TransferSettingsViewModel(PaymentInfoService paymentInfoService, IDialogService dialogService)
    {
        _paymentInfoService = paymentInfoService;
        _dialogs = dialogService;
    }

    public ObservableCollection<BankAccountItem> BankAccounts { get; } = new();
    public ObservableCollection<PixKeyItem> PixKeys { get; } = new();

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [ObservableProperty]
    public partial bool HasBankAccounts { get; set; }

    [ObservableProperty]
    public partial bool HasPixKeys { get; set; }

    [RelayCommand]
    private async Task LoadAsync()
    {
        IsLoading = true;

        var items = await _paymentInfoService.GetAllAsync();

        BankAccounts.Clear();
        PixKeys.Clear();

        foreach (var item in items)
        {
            if (!string.IsNullOrEmpty(item.BranchNumber))
            {
                BankAccounts.Add(new BankAccountItem
                {
                    Id = item.Id,
                    Description = item.Description,
                    BankCode = item.BankCode ?? "",
                    BranchNumber = item.BranchNumber,
                    BranchDigit = item.BranchDigit ?? "",
                    AccountNumber = item.AccountNumber ?? "",
                    AccountDigit = item.AccountDigit ?? ""
                });
            }

            if (!string.IsNullOrEmpty(item.PixKey))
            {
                PixKeys.Add(PixKeyItem.FromApi(item.Id, item.Description, item.PixKey, item.PixType));
            }
        }

        HasBankAccounts = BankAccounts.Count > 0;
        HasPixKeys = PixKeys.Count > 0;
        IsLoading = false;
    }

    [RelayCommand]
    private async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private async Task AddAccountAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.AddBankAccount));
    }

    [RelayCommand]
    private async Task AddPixKeyAsync()
    {
        await Shell.Current.GoToAsync(nameof(Views.AddPixKey));
    }

    [RelayCommand]
    private async Task DeletePixKeyAsync(PixKeyItem key)
    {
        bool answer = await _dialogs.ConfirmAsync("Confirmar",
            $"Deseja excluir a chave Pix '{key.Description}'?", "Sim", "Não");
        if (!answer) return;

        IsLoading = true;
        var success = await _paymentInfoService.DeleteAsync(key.Id);
        IsLoading = false;

        if (success)
        {
            PixKeys.Remove(key);
            HasPixKeys = PixKeys.Count > 0;
        }
        else
        {
            await _dialogs.ShowErrorAsync("Não foi possível excluir a chave Pix.");
        }
    }

    [RelayCommand]
    private async Task DeleteBankAccountAsync(BankAccountItem account)
    {
        bool answer = await _dialogs.ConfirmAsync("Confirmar",
            $"Deseja excluir a conta '{account.Description}'?", "Sim", "Não");
        if (!answer) return;

        IsLoading = true;
        var success = await _paymentInfoService.DeleteAsync(account.Id);
        IsLoading = false;

        if (success)
        {
            BankAccounts.Remove(account);
            HasBankAccounts = BankAccounts.Count > 0;
        }
        else
        {
            await _dialogs.ShowErrorAsync("Não foi possível excluir a conta.");
        }
    }
}
