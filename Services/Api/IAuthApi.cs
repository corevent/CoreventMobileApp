using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IAuthApi
{
    [Post("/api/auth/login")]
    Task<AuthTokensDto> Login([Body] LoginDto dto);

    [Post("/api/auth/refresh")]
    Task<AuthTokensDto> Refresh([Body] RefreshTokenDto dto);

    [Post("/api/auth/logout")]
    Task Logout([Body] RefreshTokenDto dto);

    [Post("/api/auth/forgot-password")]
    Task<MessageDto> ForgotPassword([Body] EmailDto dto);

    [Post("/api/auth/reset-password")]
    Task<MessageDto> ResetPassword([Body] ResetPasswordDto dto);

    [Post("/api/auth/verify-email")]
    Task<MessageDto> VerifyEmail([Body] EmailDto dto);

    [Post("/api/auth/register")]
    Task Register([Body] RegisterDto dto);
}
