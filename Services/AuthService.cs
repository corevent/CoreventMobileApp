using System.Diagnostics;
using System.Text.RegularExpressions;
using CoreventApp.Models;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;

namespace CoreventApp.Services;

public class AuthService : IAuthService
{
    private readonly IAuthApi _authApi;
    private readonly IUsersApi _usersApi;
    private readonly TokenService _tokenService;
    private User? _cachedUser;

    public User? CurrentCachedUser => _cachedUser;

    public AuthService(IAuthApi authApi, IUsersApi usersApi, TokenService tokenService)
    {
        _authApi = authApi;
        _usersApi = usersApi;
        _tokenService = tokenService;
    }

    public async Task<User?> LoginAsync(string email, string password)
    {
        try
        {
            var tokens = await _authApi.Login(new LoginDto(email, password));
            await _tokenService.SaveTokensAsync(tokens.AccessToken, tokens.RefreshToken);

            var profile = await _usersApi.GetProfile();
            _cachedUser = User.FromUserDataDto(profile.Data);
            return _cachedUser;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Login failed: {ex.Message}");
            return null;
        }
    }

    public async Task LogoutAsync()
    {
        try
        {
            var refreshToken = await _tokenService.GetRefreshTokenAsync();
            if (!string.IsNullOrEmpty(refreshToken))
                await _authApi.Logout(new RefreshTokenDto(refreshToken));
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Logout failed: {ex.Message}");
        }
        finally
        {
            _cachedUser = null;
            await _tokenService.ClearTokensAsync();
        }
    }

    public async Task<User?> GetCurrentUserAsync(bool forceRefresh = false)
    {
        if (!forceRefresh && _cachedUser != null)
            return _cachedUser;

        if (!await _tokenService.IsAuthenticatedAsync())
            return null;

        try
        {
            var refreshToken = await _tokenService.GetRefreshTokenAsync();
            if (!string.IsNullOrEmpty(refreshToken))
            {
                var tokens = await _authApi.Refresh(new RefreshTokenDto(refreshToken));
                await _tokenService.SaveTokensAsync(tokens.AccessToken, tokens.RefreshToken);
            }

            var profile = await _usersApi.GetProfile();
            _cachedUser = User.FromUserDataDto(profile.Data);
            return _cachedUser;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"GetCurrentUser failed: {ex.Message}");
            _cachedUser = null;
            await _tokenService.ClearTokensAsync();
            return null;
        }
    }

    public async Task<bool> UpdatePasswordAsync(string currentPassword, string newPassword)
    {
        try
        {
            await _usersApi.UpdatePassword(new UpdatePassDto(currentPassword, newPassword));
            return true;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"UpdatePassword failed: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> UpdateProfileAsync(string name, string? phoneNumber)
    {
        try
        {
            await _usersApi.UpdateUser(new UpdateUserDto(name, phoneNumber));
            _cachedUser = null;
            return true;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"UpdateProfile failed: {ex.Message}");
            return false;
        }
    }

    public async Task SendVerificationEmailAsync(string email)
    {
        try
        {
            await _authApi.VerifyEmail(new EmailDto(email));
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"SendVerificationEmail failed: {ex.Message}");
        }
    }

    public async Task<User?> CreateUserAsync(string name, string email, string password,
        string documentType, string document, string birthDate, string code)
    {
        try
        {
            document = Regex.Replace(document, @"\D", "");

            var dto = new RegisterDto(
                name, "14981234567", "https://placehold.co/300x300/jpg", email, password, birthDate, documentType, document, code);

            Debug.WriteLine($"RegisterDto: {System.Text.Json.JsonSerializer.Serialize(dto)}");

            await _authApi.Register(dto);

            // Auto-login after creation
            return await LoginAsync(email, password);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Error creating user: {ex.Message}");
            return null;
        }
    }

    public async Task SendResetCodeAsync(string email)
    {
        try
        {
            await _authApi.ForgotPassword(new EmailDto(email));
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"SendResetCode failed: {ex.Message}");
        }
    }

    public async Task<bool> ResetPasswordAsync(string email, string code, string newPassword)
    {
        try
        {
            await _authApi.ResetPassword(new ResetPasswordDto(email, code, newPassword));
            return true;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"ResetPassword failed: {ex.Message}");
            return false;
        }
    }
}
