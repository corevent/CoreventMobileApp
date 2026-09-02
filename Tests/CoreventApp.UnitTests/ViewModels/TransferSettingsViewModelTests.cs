using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class TransferSettingsViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly PaymentInfoService _paymentInfoService;
    private readonly TransferSettingsViewModel _vm;

    public TransferSettingsViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new PaymentInfoApiClient(client);
        _paymentInfoService = new PaymentInfoService(api);
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
        var pageJson = "{\"data\":[{\"id\":\"pi_1\",\"description\":\"Conta PJ\"},{\"id\":\"pi_2\",\"description\":\"Pix PF\"}],\"meta\":{\"totalItems\":2,\"totalPages\":1,\"page\":1,\"limit\":50}}";
        var item1Json = "{\"data\":{\"id\":\"pi_1\",\"userId\":\"u1\",\"description\":\"Conta PJ\",\"branchNumber\":\"1234\",\"branchDigit\":\"5\",\"accountNumber\":\"98765\",\"accountDigit\":\"0\",\"pixKey\":null,\"pixType\":null,\"bankCode\":\"001\"}}";
        var item2Json = "{\"data\":{\"id\":\"pi_2\",\"userId\":\"u1\",\"description\":\"Pix PF\",\"branchNumber\":null,\"branchDigit\":null,\"accountNumber\":null,\"accountDigit\":null,\"pixKey\":\"12345678901\",\"pixType\":\"cpf\",\"bankCode\":null}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/organizer-payment-info*")
            .Respond("application/json", pageJson);

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/organizer-payment-info/pi_1")
            .Respond("application/json", item1Json);

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/organizer-payment-info/pi_2")
            .Respond("application/json", item2Json);

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
