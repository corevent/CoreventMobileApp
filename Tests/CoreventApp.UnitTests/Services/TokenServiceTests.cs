using CoreventApp.Services;
using Microsoft.Maui.Storage;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class TokenServiceTests
{
    private readonly Mock<ISecureStorage> _secureStorageMock;
    private readonly TokenService _tokenService;

    public TokenServiceTests()
    {
        _secureStorageMock = new Mock<ISecureStorage>();
        _tokenService = new TokenService(_secureStorageMock.Object);
    }

    [Fact]
    public async Task SaveTokensAsync_ShouldSaveBothAccessAndRefreshToken()
    {
        await _tokenService.SaveTokensAsync("access-123", "refresh-456");

        _secureStorageMock.Verify(s => s.SetAsync("access_token", "access-123"), Times.Once);
        _secureStorageMock.Verify(s => s.SetAsync("refresh_token", "refresh-456"), Times.Once);
    }

    [Fact]
    public async Task GetAccessTokenAsync_ShouldReturnSavedToken()
    {
        _secureStorageMock.Setup(s => s.GetAsync("access_token"))
            .ReturnsAsync("my-access-token");

        var token = await _tokenService.GetAccessTokenAsync();

        token.ShouldBe("my-access-token");
    }

    [Fact]
    public async Task GetRefreshTokenAsync_ShouldReturnSavedToken()
    {
        _secureStorageMock.Setup(s => s.GetAsync("refresh_token"))
            .ReturnsAsync("my-refresh-token");

        var token = await _tokenService.GetRefreshTokenAsync();

        token.ShouldBe("my-refresh-token");
    }

    [Fact]
    public void ClearTokens_ShouldRemoveBothTokens()
    {
        _tokenService.ClearTokens();

        _secureStorageMock.Verify(s => s.Remove("access_token"), Times.Once);
        _secureStorageMock.Verify(s => s.Remove("refresh_token"), Times.Once);
    }

    [Fact]
    public async Task ClearTokensAsync_ShouldRemoveBothTokens()
    {
        await _tokenService.ClearTokensAsync();

        _secureStorageMock.Verify(s => s.Remove("access_token"), Times.Once);
        _secureStorageMock.Verify(s => s.Remove("refresh_token"), Times.Once);
    }

    [Theory]
    [InlineData("valid-token", true)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public async Task IsAuthenticatedAsync_ShouldReturnExpectedResult(string? token, bool expected)
    {
        _secureStorageMock.Setup(s => s.GetAsync("access_token"))
            .ReturnsAsync(token);

        var isAuth = await _tokenService.IsAuthenticatedAsync();

        isAuth.ShouldBe(expected);
    }
}
