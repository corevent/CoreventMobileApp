using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class StorageServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly StorageApiClient _api;
    private readonly StorageService _service;

    public StorageServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new StorageApiClient(httpClient);
        _service = new StorageService(_api);
    }

    [Fact]
    public async Task PresignUploadAsync_ShouldReturnPresignedData()
    {
        var presignJson = "{\"data\":{\"uploadUrl\":\"https://s3.amazonaws.com/upload\",\"publicUrl\":\"https://cdn.corevent.com/avatar1.jpg\",\"key\":\"avatars/k1\"}}";

        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/storage/presign")
            .Respond("application/json", presignJson);

        var result = await _api.PresignUploadAsync(new PresignUploadDto("avatar", "image/jpeg", null));

        result.ShouldNotBeNull();
        result.Data.UploadUrl.ShouldBe("https://s3.amazonaws.com/upload");
        result.Data.PublicUrl.ShouldBe("https://cdn.corevent.com/avatar1.jpg");
        result.Data.Key.ShouldBe("avatars/k1");
    }

    [Fact]
    public async Task ConfirmAvatarUploadAsync_ShouldSendPatchRequest()
    {
        _httpMock.Expect(HttpMethod.Patch, "https://api.corevent.com/api/users/me/avatar")
            .Respond(HttpStatusCode.OK);

        await _api.ConfirmAvatarUploadAsync("avatars/k1");
    }

    [Fact]
    public async Task ConfirmEventBannerAsync_ShouldSendPatchRequest()
    {
        _httpMock.Expect(HttpMethod.Patch, "https://api.corevent.com/api/events/evt_1/banner")
            .Respond(HttpStatusCode.OK);

        await _api.ConfirmEventBannerAsync("evt_1", "banners/b1");
    }

    [Fact]
    public async Task UploadAvatarAsync_ShouldReturnNull_OnPresignFailure()
    {
        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/storage/presign")
            .Respond(HttpStatusCode.InternalServerError);

        using var stream = new MemoryStream();
        var result = await _service.UploadAvatarAsync(stream, "image/jpeg");

        result.ShouldBeNull();
    }
}
