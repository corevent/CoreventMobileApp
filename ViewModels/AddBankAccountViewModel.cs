using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class AddBankAccountViewModel : ObservableObject
{
    private readonly PaymentInfoService _paymentInfoService;
    private readonly IDialogService _dialogs;

    public AddBankAccountViewModel(PaymentInfoService paymentInfoService, IDialogService dialogService)
    {
        _paymentInfoService = paymentInfoService;
        _dialogs = dialogService;
    }

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

    [ObservableProperty]
    public partial bool IsLoading { get; set; }

    [RelayCommand]
    private async Task SaveAsync()
    {
        if (string.IsNullOrWhiteSpace(Description))
        {
            await _dialogs.ShowErrorAsync("A descrição é obrigatória.");
            return;
        }

        if (string.IsNullOrWhiteSpace(BankCode) || BankCode.Trim().Length != 3 || !BankCode.All(char.IsDigit))
        {
            await _dialogs.ShowErrorAsync("O código do banco deve ter exatamente 3 dígitos.");
            return;
        }

        if (string.IsNullOrWhiteSpace(BranchNumber) || BranchNumber.Trim().Length < 4 || !BranchNumber.All(char.IsDigit))
        {
            await _dialogs.ShowErrorAsync("A agência deve ter pelo menos 4 dígitos.");
            return;
        }

        if (string.IsNullOrWhiteSpace(AccountNumber))
        {
            await _dialogs.ShowErrorAsync("O número da conta é obrigatório.");
            return;
        }

        var dto = new CreateOrganizerPaymentInfoDto(
            Description,
            BranchNumber.Trim(),
            string.IsNullOrWhiteSpace(BranchDigit) ? null : BranchDigit,
            AccountNumber,
            string.IsNullOrWhiteSpace(AccountDigit) ? null : AccountDigit,
            null,
            null,
            BankCode);

        IsLoading = true;
        var result = await _paymentInfoService.CreateAsync(dto);
        IsLoading = false;

        if (result != null)
            await Shell.Current.GoToAsync("..");
        else
            await _dialogs.ShowErrorAsync("Não foi possível salvar a conta. Tente novamente.");
    }

    [RelayCommand]
    private async Task CancelAsync()
    {
        await Shell.Current.GoToAsync("..");
    }
}
