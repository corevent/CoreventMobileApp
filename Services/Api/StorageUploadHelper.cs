using System.Net.Http.Headers;

namespace CoreventApp.Services.Api;

/// <summary>
/// Direct PUT to presigned S3 URLs. Kept outside Refit because the upload
/// goes to external storage, not through the Corevent API (no base address,
/// no auth handler).
/// </summary>
public static class StorageUploadHelper
{
    public static async Task<bool> UploadImageAsync(string uploadUrl, Stream imageStream, string contentType)
    {
        try
        {
            using var uploadClient = new HttpClient();
            using var streamContent = new StreamContent(imageStream);
            streamContent.Headers.ContentType = new MediaTypeHeaderValue(contentType);
            var response = await uploadClient.PutAsync(uploadUrl, streamContent);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }
}
