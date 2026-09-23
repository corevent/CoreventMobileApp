using System.Net.Http.Headers;

namespace CoreventApp.Services.Api;

/// <summary>
/// Direct PUT to presigned S3 URLs. Kept outside Refit because the upload
/// goes to external storage, not through the Corevent API (no base address,
/// no auth handler).
/// </summary>
public interface IStorageUploadService
{
    Task<bool> UploadImageAsync(string uploadUrl, Stream imageStream, string contentType, CancellationToken cancellationToken = default);
}

public sealed class StorageUploadService : IStorageUploadService
{
    private readonly HttpClient _client;

    public StorageUploadService(HttpClient client)
    {
        _client = client;
    }

    public async Task<bool> UploadImageAsync(string uploadUrl, Stream imageStream, string contentType, CancellationToken cancellationToken = default)
    {
        try
        {
            using var streamContent = new StreamContent(imageStream);
            streamContent.Headers.ContentType = new MediaTypeHeaderValue(contentType);
            var response = await _client.PutAsync(uploadUrl, streamContent, cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or InvalidOperationException)
        {
            System.Diagnostics.Debug.WriteLine($"UploadImageAsync failed: {ex.Message}");
            return false;
        }
    }
}
