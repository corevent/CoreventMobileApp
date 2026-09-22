using Microsoft.Maui.Storage;

namespace CoreventApp.Services;

public class TokenService
{
    private const string AccessTokenKey = "access_token";
    private const string RefreshTokenKey = "refresh_token";
    private readonly ISecureStorage _secureStorage;

    public TokenService(ISecureStorage? secureStorage = null)
    {
        _secureStorage = secureStorage ?? SecureStorage.Default;
    }

    public async Task SaveTokensAsync(string accessToken, string refreshToken)
    {
        await _secureStorage.SetAsync(AccessTokenKey, accessToken);
        await _secureStorage.SetAsync(RefreshTokenKey, refreshToken);
    }

    public async Task<string?> GetAccessTokenAsync()
    {
        return await _secureStorage.GetAsync(AccessTokenKey);
    }

    public async Task<string?> GetRefreshTokenAsync()
    {
        return await _secureStorage.GetAsync(RefreshTokenKey);
    }

    public Task ClearTokensAsync()
    {
        _secureStorage.Remove(AccessTokenKey);
        _secureStorage.Remove(RefreshTokenKey);
        return Task.CompletedTask;
    }

    public async Task<bool> IsAuthenticatedAsync()
    {
        var token = await GetAccessTokenAsync();
        return !string.IsNullOrEmpty(token);
    }
}
