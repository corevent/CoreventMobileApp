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

public class AuthServiceTests
{
    private readonly Mock<ISecureStorage> _secureStorageMock;
    private readonly TokenService _tokenService;
    private readonly MockHttpMessageHandler _httpMock;
    private readonly AuthApiClient _authApi;
    private readonly UsersApiClient _usersApi;
    private readonly AuthService _authService;

    public AuthServiceTests()
    {
        _secureStorageMock = new Mock<ISecureStorage>();
        _tokenService = new TokenService(_secureStorageMock.Object);

        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _authApi = new AuthApiClient(httpClient);
        _usersApi = new UsersApiClient(httpClient);
        _authService = new AuthService(_authApi, _usersApi, _tokenService);
    }

    [Fact]
    public async Task LoginAsync_ShouldSaveTokensAndCacheUser_OnSuccess()
    {
        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/auth/login")
            .Respond("application/json", "{\"accessToken\":\"jwt-acc\",\"refreshToken\":\"jwt-ref\"}");

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me")
            .Respond("application/json", "{\"data\":{\"id\":\"u1\",\"name\":\"Lucas\",\"email\":\"lucas@example.com\",\"cpf\":\"123\",\"birthDate\":\"1995-01-01\",\"phoneNumber\":\"11999999999\",\"avatarUrl\":\"\",\"createdAt\":\"2026-01-01T00:00:00.000Z\"}}");

        var user = await _authService.LoginAsync("lucas@example.com", "senha123");

        user.ShouldNotBeNull();
        user.Id.ShouldBe("u1");
        user.Name.ShouldBe("Lucas");
        _authService.CurrentCachedUser.ShouldBe(user);

        _secureStorageMock.Verify(s => s.SetAsync("access_token", "jwt-acc"), Times.Once);
        _secureStorageMock.Verify(s => s.SetAsync("refresh_token", "jwt-ref"), Times.Once);
    }

    [Fact]
    public async Task LoginAsync_ShouldReturnNull_WhenApiReturnsError()
    {
        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/auth/login")
            .Respond(HttpStatusCode.BadRequest, "application/json", "{\"message\":\"Invalid credentials\"}");

        var user = await _authService.LoginAsync("wrong@example.com", "wrongpass");

        user.ShouldBeNull();
        _authService.CurrentCachedUser.ShouldBeNull();
    }

    [Fact]
    public async Task LogoutAsync_ShouldClearCacheAndTokens()
    {
        _secureStorageMock.Setup(s => s.GetAsync("refresh_token")).ReturnsAsync("my-ref-token");

        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/auth/logout")
            .Respond(HttpStatusCode.OK);

        await _authService.LogoutAsync();

        _authService.CurrentCachedUser.ShouldBeNull();
        _secureStorageMock.Verify(s => s.Remove("access_token"), Times.Once);
        _secureStorageMock.Verify(s => s.Remove("refresh_token"), Times.Once);
    }
}
