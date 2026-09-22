using System.Net;
using System.Text;
using System.Text.Json;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class FavoritesApiIntegrationTests
{
    private static IFavoritesApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IFavoritesApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task CreateAsync_ShouldPostWithoutBody()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/favorites/events/evt_1")
            .Respond("application/json", "{\"data\":{\"id\":\"fav_1\",\"userId\":\"u1\",\"eventId\":\"evt_1\"}}");

        var api = CreateApi(httpMock);

        var result = await api.CreateAsync("evt_1");

        result.Data.Id.ShouldBe("fav_1");
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task DeleteAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Delete, "https://api.corevent.com/api/favorites/fav_1")
            .Respond(HttpStatusCode.OK);

        var api = CreateApi(httpMock);

        await api.DeleteAsync("fav_1");

        httpMock.VerifyNoOutstandingExpectation();
    }
}
