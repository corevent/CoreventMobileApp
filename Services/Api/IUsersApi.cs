using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IUsersApi
{
    [Post("/api/users")]
    Task<UserResponseDto> CreateUser([Body] CreateUserDto dto);

    [Patch("/api/users")]
    Task<UserResponseDto> UpdateUser([Body] UpdateUserDto dto);

    [Patch("/api/users/pass")]
    Task<MessageDto> UpdatePassword([Body] UpdatePassDto dto);

    [Get("/api/users/{id}")]
    Task<UserResponseDto> GetUserByIdAsync(string id);

    [Get("/api/users/me")]
    Task<UserResponseDto> GetProfile();
}
