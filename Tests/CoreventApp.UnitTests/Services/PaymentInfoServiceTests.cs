using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class PaymentInfoServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly PaymentInfoApiClient _api;
    private readonly PaymentInfoService _service;

    public PaymentInfoServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new PaymentInfoApiClient(httpClient);
        _service = new PaymentInfoService(_api);
    }

    [Fact]
    public async Task CreateAsync_ShouldReturnData_OnSuccess()
    {
        var responseJson = "{\"data\":{\"id\":\"pi_1\",\"userId\":\"u1\",\"description\":\"Minha chave Pix\",\"branchNumber\":null,\"branchDigit\":null,\"accountNumber\":null,\"accountDigit\":null,\"pixKey\":\"12345678901\",\"pixType\":\"cpf\",\"bankCode\":null}}";

        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/users/me/organizer-payment-info")
            .Respond("application/json", responseJson);

        var dto = new CreateOrganizerPaymentInfoDto("Minha chave Pix", null, null, null, null, "12345678901", "cpf", null);
        var result = await _service.CreateAsync(dto);

        result.ShouldNotBeNull();
        result.Id.ShouldBe("pi_1");
        result.Description.ShouldBe("Minha chave Pix");
        result.PixKey.ShouldBe("12345678901");
        result.PixType.ShouldBe("cpf");
    }

    [Fact]
    public async Task CreateAsync_ShouldReturnNull_OnError()
    {
        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/users/me/organizer-payment-info")
            .Respond(HttpStatusCode.BadRequest);

        var dto = new CreateOrganizerPaymentInfoDto("Chave", null, null, null, null, "123", "cpf", null);
        var result = await _service.CreateAsync(dto);

        result.ShouldBeNull();
    }

    [Fact]
    public async Task GetAllAsync_ShouldFetchAllItems_WhenItemsExist()
    {
        var pageJson = "{\"data\":[{\"id\":\"pi_1\",\"description\":\"Pix Principal\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":50}}";
        var itemJson = "{\"data\":{\"id\":\"pi_1\",\"userId\":\"u1\",\"description\":\"Pix Principal\",\"branchNumber\":null,\"branchDigit\":null,\"accountNumber\":null,\"accountDigit\":null,\"pixKey\":\"123\",\"pixType\":\"cpf\",\"bankCode\":null}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/organizer-payment-info*")
            .Respond("application/json", pageJson);

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/organizer-payment-info/pi_1")
            .Respond("application/json", itemJson);

        var results = await _service.GetAllAsync();

        results.ShouldNotBeNull();
        results.Count.ShouldBe(1);
        results[0].Id.ShouldBe("pi_1");
        results[0].Description.ShouldBe("Pix Principal");
    }

    [Fact]
    public async Task DeleteAsync_ShouldReturnTrue_OnSuccess()
    {
        _httpMock.Expect(HttpMethod.Delete, "https://api.corevent.com/api/users/me/organizer-payment-info/pi_1")
            .Respond(HttpStatusCode.OK);

        var success = await _service.DeleteAsync("pi_1");

        success.ShouldBeTrue();
    }
}
