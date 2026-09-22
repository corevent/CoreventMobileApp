using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IStorageApi
{
    [Post("/api/storage/presign")]
    Task<PresignUploadResponseDto> PresignUploadAsync([Body] PresignUploadDto dto);

    [Patch("/api/users/me/avatar")]
    Task ConfirmAvatarUploadAsync([Body] ConfirmImageUploadDto dto);

    [Patch("/api/events/{eventId}/banner")]
    Task ConfirmEventBannerAsync(string eventId, [Body] ConfirmImageUploadDto dto);
}
