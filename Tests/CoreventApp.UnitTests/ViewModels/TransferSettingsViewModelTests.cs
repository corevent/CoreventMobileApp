using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class TransferSettingsViewModelTests
{
    private readonly Mock<IPaymentInfoApi> _apiMock;
    private readonly PaymentInfoService _paymentInfoService;
    private readonly TransferSettingsViewModel _vm;

    public TransferSettingsViewModelTests()
    {
        _apiMock = new Mock<IPaymentInfoApi>();
        _paymentInfoService = new PaymentInfoService(_apiMock.Object);
        _vm = new TransferSettingsViewModel(_paymentInfoService);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.BankAccounts.ShouldBeEmpty();
        _vm.PixKeys.ShouldBeEmpty();
        _vm.HasBankAccounts.ShouldBeFalse();
        _vm.HasPixKeys.ShouldBeFalse();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadAsync_ShouldPopulateBankAccountsAndPixKeys()
    {
        _apiMock.Setup(a => a.GetAllAsync(1, 50))
            .ReturnsAsync(new OrganizerPaymentInfoPageDto(
                new List<ListOrganizerPaymentInfoDto>
                {
                    new("pi_1", "Conta PJ"),
                    new("pi_2", "Pix PF")
                },
                new PaginationMetaDto(2, 1, 1, 50)));
        _apiMock.Setup(a => a.GetByIdAsync("pi_1"))
            .ReturnsAsync(new OrganizerPaymentInfoResDto(
                new OrganizerPaymentInfoDataDto("pi_1", "u1", "Conta PJ", "1234", "5", "98765", "0", null, null, "001")));
        _apiMock.Setup(a => a.GetByIdAsync("pi_2"))
            .ReturnsAsync(new OrganizerPaymentInfoResDto(
                new OrganizerPaymentInfoDataDto("pi_2", "u1", "Pix PF", null, null, null, null, "12345678901", "cpf", null)));

        await _vm.LoadCommand.ExecuteAsync(null);

        _vm.BankAccounts.Count.ShouldBe(1);
        _vm.BankAccounts[0].Description.ShouldBe("Conta PJ");
        _vm.HasBankAccounts.ShouldBeTrue();

        _vm.PixKeys.Count.ShouldBe(1);
        _vm.PixKeys[0].Description.ShouldBe("Pix PF");
        _vm.PixKeys[0].Type.ShouldBe("CPF");
        _vm.HasPixKeys.ShouldBeTrue();
    }

    [Fact]
    public void BankAccountItem_DisplayText_ShouldFormatCorrectly()
    {
        var item = new BankAccountItem
        {
            Id = "ba_1",
            Description = "Conta PJ",
            BankCode = "341",
            BranchNumber = "0001",
            AccountNumber = "12345",
            AccountDigit = "6"
        };

        item.DisplayText.ShouldBe("Conta PJ • CÓD 341 • AG 0001 • CONTA 12345-6");
    }

    [Theory]
    [InlineData("cpf", "CPF")]
    [InlineData("email", "Email")]
    [InlineData("phone", "Telefone")]
    [InlineData("cnpj", "CNPJ")]
    [InlineData("random", "Chave Aleatória")]
    public void PixKeyItem_FromApi_ShouldMapTypeCorrectly(string apiType, string expectedUiType)
    {
        var item = PixKeyItem.FromApi("pix_1", "Meu Pix", "123456", apiType);

        item.Id.ShouldBe("pix_1");
        item.Description.ShouldBe("Meu Pix");
        item.Key.ShouldBe("123456");
        item.Type.ShouldBe(expectedUiType);
    }
}
