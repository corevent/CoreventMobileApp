using System.Diagnostics;
using System.Text.Json;
using Refit;

namespace CoreventApp.Services.Api;

/// <summary>
/// Bridges Refit's exception-based errors (<see cref="ApiException"/>) to the
/// previous "return null/false/empty page" contract used across ViewModels,
/// so call sites stay small after the *Service wrappers are removed.
/// </summary>
public static class ApiResult
{
    public static async Task<T?> TryExecuteAsync<T>(Func<Task<T>> action, string? context = null)
    {
        try
        {
            return await action();
        }
        catch (ApiException ex)
        {
            Debug.WriteLine($"{context ?? "API call"} failed: {(int)ex.StatusCode} ({ex.StatusCode}). Content: {ex.Content}");
            return default;
        }
        catch (HttpRequestException ex)
        {
            Debug.WriteLine($"{context ?? "API call"} failed: no response ({ex.Message})");
            return default;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"{context ?? "API call"} failed: {ex.Message}");
            return default;
        }
    }

    public static async Task<bool> TryExecuteAsync(Func<Task> action, string? context = null)
    {
        try
        {
            await action();
            return true;
        }
        catch (ApiException ex)
        {
            Debug.WriteLine($"{context ?? "API call"} failed: {(int)ex.StatusCode} ({ex.StatusCode}). Content: {ex.Content}");
            return false;
        }
        catch (HttpRequestException ex)
        {
            Debug.WriteLine($"{context ?? "API call"} failed: no response ({ex.Message})");
            return false;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"{context ?? "API call"} failed: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Best-effort extraction of the backend's {"message":"..."} error payload.
    /// </summary>
    public static string? ExtractMessage(ApiException ex)
    {
        if (!ex.HasContent)
            return null;

        try
        {
            using var doc = JsonDocument.Parse(ex.Content!);
            if (doc.RootElement.TryGetProperty("message", out var message))
                return message.GetString();
        }
        catch (JsonException)
        {
        }

        return null;
    }
}
