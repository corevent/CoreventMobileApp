using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class AddBankAccountViewModelTests
{
    private readonly AddBankAccountViewModel _vm;

    public AddBankAccountViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = Refit.RestService.For<IPaymentInfoApi>(client, RefitConfig.CreateSettings());
        var service = new PaymentInfoService(api);

        _vm = new AddBankAccountViewModel(service);
    }

    [Fact]
    public void InitialState_ShouldBeDefault()
    {
        _vm.Description.ShouldBeEmpty();
        _vm.BankCode.ShouldBeEmpty();
        _vm.BranchNumber.ShouldBeEmpty();
        _vm.AccountNumber.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public void Properties_ShouldUpdateValues()
    {
        _vm.Description = "Conta Principal";
        _vm.BankCode = "001";
        _vm.BranchNumber = "1234";
        _vm.BranchDigit = "5";
        _vm.AccountNumber = "987654";
        _vm.AccountDigit = "0";

        _vm.Description.ShouldBe("Conta Principal");
        _vm.BankCode.ShouldBe("001");
        _vm.BranchNumber.ShouldBe("1234");
        _vm.BranchDigit.ShouldBe("5");
        _vm.AccountNumber.ShouldBe("987654");
        _vm.AccountDigit.ShouldBe("0");
    }
}
