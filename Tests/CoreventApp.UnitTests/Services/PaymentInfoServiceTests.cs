using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class PaymentInfoServiceTests
{
    private readonly Mock<IPaymentInfoApi> _apiMock;
    private readonly PaymentInfoService _service;

    public PaymentInfoServiceTests()
    {
        _apiMock = new Mock<IPaymentInfoApi>();
        _service = new PaymentInfoService(_apiMock.Object);
    }

    private static OrganizerPaymentInfoDataDto Item(string id, string description) =>
        new(id, "u1", description, null, null, null, null, "12345678901", "cpf", null);

    [Fact]
    public async Task CreateAsync_ShouldReturnData_OnSuccess()
    {
        var dto = new CreateOrganizerPaymentInfoDto("Minha chave Pix", null, null, null, null, "12345678901", "cpf", null);
        _apiMock.Setup(a => a.CreateAsync(dto))
            .ReturnsAsync(new OrganizerPaymentInfoResDto(Item("pi_1", "Minha chave Pix")));

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
        var dto = new CreateOrganizerPaymentInfoDto("Chave", null, null, null, null, "123", "cpf", null);
        _apiMock.Setup(a => a.CreateAsync(dto)).ThrowsAsync(new HttpRequestException("boom"));

        var result = await _service.CreateAsync(dto);

        result.ShouldBeNull();
    }

    [Fact]
    public async Task GetAllAsync_ShouldFetchAllItems_WhenItemsExist()
    {
        _apiMock.Setup(a => a.GetAllAsync(1, 50))
            .ReturnsAsync(new OrganizerPaymentInfoPageDto(
                new List<ListOrganizerPaymentInfoDto> { new("pi_1", "Pix Principal") },
                new PaginationMetaDto(1, 1, 1, 50)));
        _apiMock.Setup(a => a.GetByIdAsync("pi_1"))
            .ReturnsAsync(new OrganizerPaymentInfoResDto(Item("pi_1", "Pix Principal")));

        var results = await _service.GetAllAsync();

        results.ShouldNotBeNull();
        results.Count.ShouldBe(1);
        results[0].Id.ShouldBe("pi_1");
        results[0].Description.ShouldBe("Pix Principal");
    }

    [Fact]
    public async Task DeleteAsync_ShouldReturnTrue_OnSuccess()
    {
        _apiMock.Setup(a => a.DeleteAsync("pi_1")).Returns(Task.CompletedTask);

        var success = await _service.DeleteAsync("pi_1");

        success.ShouldBeTrue();
    }
}
