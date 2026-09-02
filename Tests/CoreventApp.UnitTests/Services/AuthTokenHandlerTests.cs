using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using Microsoft.Maui.Storage;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class AuthTokenHandlerTests
{
    [Fact]
    public async Task SendAsync_ShouldAddBearerHeader_WhenAccessTokenExists()
    {
        var secureStorageMock = new Mock<ISecureStorage>();
        secureStorageMock.Setup(s => s.GetAsync("access_token")).ReturnsAsync("my-jwt-token");

        var tokenService = new TokenService(secureStorageMock.Object);
        var authHttpMock = new MockHttpMessageHandler();
        var authApi = new AuthApiClient(authHttpMock.ToHttpClient());

        var innerHttpMock = new MockHttpMessageHandler();
        innerHttpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events")
            .WithHeaders("Authorization", "Bearer my-jwt-token")
            .Respond(HttpStatusCode.OK, "application/json", "[]");

        var handler = new AuthTokenHandler(tokenService, authApi)
        {
            InnerHandler = innerHttpMock
        };

        var invoker = new HttpMessageInvoker(handler);
        var request = new HttpRequestMessage(HttpMethod.Get, "https://api.corevent.com/api/events");

        var response = await invoker.SendAsync(request, CancellationToken.None);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        innerHttpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task SendAsync_ShouldRefreshTokensAndRetry_WhenReceives401Unauthorized()
    {
        var secureStorageMock = new Mock<ISecureStorage>();
        secureStorageMock.Setup(s => s.GetAsync("access_token")).ReturnsAsync("expired-token");
        secureStorageMock.Setup(s => s.GetAsync("refresh_token")).ReturnsAsync("valid-refresh-token");

        var tokenService = new TokenService(secureStorageMock.Object);

        var authHttpMock = new MockHttpMessageHandler();
        authHttpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/auth/refresh")
            .Respond("application/json", "{\"accessToken\":\"new-access-token\",\"refreshToken\":\"new-refresh-token\"}");

        var authHttpClient = authHttpMock.ToHttpClient();
        authHttpClient.BaseAddress = new Uri("https://api.corevent.com");
        var authApi = new AuthApiClient(authHttpClient);

        var innerHttpMock = new MockHttpMessageHandler();
        // 1st request -> 401 Unauthorized
        innerHttpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events")
            .WithHeaders("Authorization", "Bearer expired-token")
            .Respond(HttpStatusCode.Unauthorized);

        // 2nd request (retry) -> 200 OK with new token
        innerHttpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events")
            .WithHeaders("Authorization", "Bearer new-access-token")
            .Respond(HttpStatusCode.OK, "application/json", "[]");

        var handler = new AuthTokenHandler(tokenService, authApi)
        {
            InnerHandler = innerHttpMock
        };

        var invoker = new HttpMessageInvoker(handler);
        var request = new HttpRequestMessage(HttpMethod.Get, "https://api.corevent.com/api/events");

        var response = await invoker.SendAsync(request, CancellationToken.None);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        secureStorageMock.Verify(s => s.SetAsync("access_token", "new-access-token"), Times.Once);
        secureStorageMock.Verify(s => s.SetAsync("refresh_token", "new-refresh-token"), Times.Once);
        innerHttpMock.VerifyNoOutstandingExpectation();
        authHttpMock.VerifyNoOutstandingExpectation();
    }
}
