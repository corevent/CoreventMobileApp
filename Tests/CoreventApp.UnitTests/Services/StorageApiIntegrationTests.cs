using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class StorageApiIntegrationTests
{
    private static IStorageApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IStorageApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task PresignUploadAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":{\"uploadUrl\":\"https://s3.amazonaws.com/upload\",\"key\":\"avatars/k1\",\"publicUrl\":\"https://cdn.corevent.com/a.jpg\",\"expiresIn\":300}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/storage/presign")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.PresignUploadAsync(new PresignUploadDto("avatar", "image/jpeg", null));

        result.Data.Key.ShouldBe("avatars/k1");
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task ConfirmAvatarUploadAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(new HttpMethod("PATCH"), "https://api.corevent.com/api/users/me/avatar")
            .Respond(HttpStatusCode.OK);

        var api = CreateApi(httpMock);

        await api.ConfirmAvatarUploadAsync(new ConfirmImageUploadDto("avatars/k1"));

        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task ConfirmEventBannerAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(new HttpMethod("PATCH"), "https://api.corevent.com/api/events/evt_1/banner")
            .Respond(HttpStatusCode.OK);

        var api = CreateApi(httpMock);

        await api.ConfirmEventBannerAsync("evt_1", new ConfirmImageUploadDto("banners/b1"));

        httpMock.VerifyNoOutstandingExpectation();
    }
}
