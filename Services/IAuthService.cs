using CoreventApp.Models;

namespace CoreventApp.Services;

public interface IAuthService
{
    User? CurrentCachedUser { get; }

    Task<User?> LoginAsync(string email, string password);
    Task LogoutAsync();
    Task<User?> GetCurrentUserAsync(bool forceRefresh = false);

    Task<bool> UpdatePasswordAsync(string currentPassword, string newPassword);
    Task<bool> UpdateProfileAsync(string name, string? phoneNumber);

    Task<bool> SendVerificationEmailAsync(string email);
    Task<User?> CreateUserAsync(string name, string email, string password,
        string documentType, string document, string birthDate, string code);

    Task<bool> SendResetCodeAsync(string email);
    Task<bool> ResetPasswordAsync(string email, string code, string newPassword);
}
