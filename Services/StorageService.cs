using System.Diagnostics;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;

namespace CoreventApp.Services;

public class StorageService
{
    private readonly IStorageApi _api;

    public StorageService(IStorageApi api)
    {
        _api = api;
    }

    public async Task<string?> UploadAvatarAsync(Stream imageStream, string contentType)
    {
        try
        {
            var presign = await _api.PresignUploadAsync(new("avatar", contentType, null));
            var uploaded = await StorageUploadHelper.UploadImageAsync(presign.Data.UploadUrl, imageStream, contentType);
            if (!uploaded) return null;

            await _api.ConfirmAvatarUploadAsync(new ConfirmImageUploadDto(presign.Data.Key));
            return presign.Data.PublicUrl;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"UploadAvatar failed: {ex.Message}");
            return null;
        }
    }

    public async Task<string?> UploadEventBannerAsync(string eventId, Stream imageStream, string contentType)
    {
        try
        {
            var presign = await _api.PresignUploadAsync(new("event_banner", contentType, eventId));
            var uploaded = await StorageUploadHelper.UploadImageAsync(presign.Data.UploadUrl, imageStream, contentType);
            if (!uploaded) return null;

            await _api.ConfirmEventBannerAsync(eventId, new ConfirmImageUploadDto(presign.Data.Key));
            return presign.Data.PublicUrl;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"UploadEventBanner failed: {ex.Message}");
            return null;
        }
    }
}
