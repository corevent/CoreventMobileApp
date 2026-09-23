using System.Net;
using System.Text;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using Microsoft.Maui.Storage;
using Moq;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class AuthServiceTests
{
    private readonly Mock<ISecureStorage> _secureStorageMock;
    private readonly TokenService _tokenService;
    private readonly Mock<IAuthApi> _authApiMock;
    private readonly Mock<IUsersApi> _usersApiMock;
    private readonly AuthService _authService;

    public AuthServiceTests()
    {
        _secureStorageMock = new Mock<ISecureStorage>();
        _tokenService = new TokenService(_secureStorageMock.Object);

        _authApiMock = new Mock<IAuthApi>();
        _usersApiMock = new Mock<IUsersApi>();
        _authService = new AuthService(_authApiMock.Object, _usersApiMock.Object, _tokenService);
    }

    private static UserResponseDto Profile() => new(new UserDataDto(
        "u1", "Lucas", "lucas@example.com", "123", "1995-01-01", "11999999999", "",
        new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)));

    [Fact]
    public async Task LoginAsync_ShouldSaveTokensAndCacheUser_OnSuccess()
    {
        _authApiMock.Setup(a => a.Login(It.IsAny<LoginDto>()))
            .ReturnsAsync(new AuthTokensDto("jwt-acc", "jwt-ref"));
        _usersApiMock.Setup(a => a.GetProfile()).ReturnsAsync(Profile());

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
        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.corevent.com/api/auth/login");
        var response = new HttpResponseMessage(HttpStatusCode.BadRequest)
        {
            RequestMessage = request,
            Content = new StringContent("{\"message\":\"Invalid credentials\"}", Encoding.UTF8, "application/json")
        };
        _authApiMock.Setup(a => a.Login(It.IsAny<LoginDto>()))
            .ThrowsAsync(await ApiException.Create(request, HttpMethod.Post, response, new RefitSettings()));

        var user = await _authService.LoginAsync("wrong@example.com", "wrongpass");

        user.ShouldBeNull();
        _authService.CurrentCachedUser.ShouldBeNull();
    }

    [Fact]
    public async Task LogoutAsync_ShouldClearCacheAndTokens()
    {
        _secureStorageMock.Setup(s => s.GetAsync("refresh_token")).ReturnsAsync("my-ref-token");
        _authApiMock.Setup(a => a.Logout(It.IsAny<RefreshTokenDto>())).Returns(Task.CompletedTask);

        await _authService.LogoutAsync();

        _authService.CurrentCachedUser.ShouldBeNull();
        _secureStorageMock.Verify(s => s.Remove("access_token"), Times.Once);
        _secureStorageMock.Verify(s => s.Remove("refresh_token"), Times.Once);
    }

    [Fact]
    public async Task SendVerificationEmailAsync_ShouldReturnFalse_WhenApiFails()
    {
        _authApiMock.Setup(a => a.VerifyEmail(It.IsAny<EmailDto>()))
            .ThrowsAsync(new HttpRequestException("offline"));

        var sent = await _authService.SendVerificationEmailAsync("lucas@example.com");

        sent.ShouldBeFalse();
    }

    [Fact]
    public async Task SendResetCodeAsync_ShouldReturnTrue_WhenApiSucceeds()
    {
        _authApiMock.Setup(a => a.ForgotPassword(It.IsAny<EmailDto>()))
            .ReturnsAsync(new MessageDto("Código enviado"));

        var sent = await _authService.SendResetCodeAsync("lucas@example.com");

        sent.ShouldBeTrue();
    }

    [Fact]
    public async Task Login_ShouldSerializeBodyLikeManualClient()
    {
        string? capturedBody = null;
        var httpMock = new MockHttpMessageHandler();
        httpMock.When(HttpMethod.Post, "https://api.corevent.com/api/auth/login")
            .Respond(async req =>
            {
                capturedBody = req.Content is null ? null : await req.Content.ReadAsStringAsync();
                return new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent("{\"accessToken\":\"jwt-acc\",\"refreshToken\":\"jwt-ref\"}", Encoding.UTF8, "application/json")
                };
            });

        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        var api = RestService.For<IAuthApi>(httpClient, RefitConfig.CreateSettings());

        var tokens = await api.Login(new LoginDto("lucas@example.com", "senha123"));

        tokens.AccessToken.ShouldBe("jwt-acc");
        capturedBody.ShouldBe("{\"email\":\"lucas@example.com\",\"password\":\"senha123\"}");
    }
}
