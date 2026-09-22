using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class StorageServiceTests
{
    private readonly Mock<IStorageApi> _apiMock;
    private readonly StorageService _service;

    public StorageServiceTests()
    {
        _apiMock = new Mock<IStorageApi>();
        _service = new StorageService(_apiMock.Object);
    }

    [Fact]
    public async Task UploadAvatarAsync_ShouldReturnNull_OnPresignFailure()
    {
        _apiMock.Setup(a => a.PresignUploadAsync(It.IsAny<PresignUploadDto>()))
            .ThrowsAsync(new HttpRequestException("boom"));

        using var stream = new MemoryStream();
        var result = await _service.UploadAvatarAsync(stream, "image/jpeg");

        result.ShouldBeNull();
    }

    [Fact]
    public async Task UploadEventBannerAsync_ShouldReturnNull_OnPresignFailure()
    {
        _apiMock.Setup(a => a.PresignUploadAsync(It.IsAny<PresignUploadDto>()))
            .ThrowsAsync(new HttpRequestException("boom"));

        using var stream = new MemoryStream();
        var result = await _service.UploadEventBannerAsync("evt_1", stream, "image/jpeg");

        result.ShouldBeNull();
    }
}
