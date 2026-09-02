using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class AddPixKeyViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly AddPixKeyViewModel _vm;

    public AddPixKeyViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new PaymentInfoApiClient(client);
        var service = new PaymentInfoService(api);

        _vm = new AddPixKeyViewModel(service);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultKeyTypes()
    {
        _vm.KeyTypes.ShouldContain("Email");
        _vm.KeyTypes.ShouldContain("CPF");
        _vm.KeyTypes.ShouldContain("CNPJ");
        _vm.KeyTypes.ShouldContain("Telefone");
        _vm.KeyTypes.ShouldContain("Chave Aleatória");
        _vm.SelectedKeyType.ShouldBe("Email");
        _vm.Description.ShouldBeEmpty();
        _vm.KeyValue.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public void Properties_ShouldUpdateValues()
    {
        _vm.Description = "Meu Pix Nubank";
        _vm.SelectedKeyType = "CPF";
        _vm.KeyValue = "123.456.789-00";

        _vm.Description.ShouldBe("Meu Pix Nubank");
        _vm.SelectedKeyType.ShouldBe("CPF");
        _vm.KeyValue.ShouldBe("123.456.789-00");
    }
}
