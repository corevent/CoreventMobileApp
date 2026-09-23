using System.Diagnostics;
using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using CoreventApp.Models.Dtos;

namespace CoreventApp.Services.Api;

public class AuthTokenHandler : DelegatingHandler
{
    /// <summary>
    /// Named HttpClient used only for token refresh. It is registered WITHOUT this
    /// handler to avoid a dependency cycle (and infinite 401 recursion).
    /// </summary>
    public const string RefreshClientName = "auth-refresh";

    private readonly TokenService _tokenService;
    private readonly IHttpClientFactory _httpClientFactory;

    public AuthTokenHandler(TokenService tokenService, IHttpClientFactory httpClientFactory)
    {
        _tokenService = tokenService;
        _httpClientFactory = httpClientFactory;
    }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var accessToken = await _tokenService.GetAccessTokenAsync();
        if (!string.IsNullOrEmpty(accessToken))
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        var response = await base.SendAsync(request, cancellationToken);

        if (response.StatusCode != HttpStatusCode.Unauthorized)
            return response;

        var refreshToken = await _tokenService.GetRefreshTokenAsync();
        if (string.IsNullOrEmpty(refreshToken))
            return response;

        try
        {
            var tokens = await RefreshAsync(refreshToken, cancellationToken);
            await _tokenService.SaveTokensAsync(tokens.AccessToken, tokens.RefreshToken);

            var retry = await CloneRequest(request);
            retry.Headers.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
            return await base.SendAsync(retry, cancellationToken);
        }
        catch (Exception ex) when (ex is HttpRequestException or JsonException)
        {
            Debug.WriteLine($"Token refresh failed: {ex.Message}");
            await _tokenService.ClearTokensAsync();
            return response;
        }
    }

    private async Task<AuthTokensDto> RefreshAsync(string refreshToken, CancellationToken cancellationToken)
    {
        var refreshClient = _httpClientFactory.CreateClient(RefreshClientName);
        var json = JsonSerializer.Serialize(new RefreshTokenDto(refreshToken), JsonConfig.Options);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");
        using var refreshResponse = await refreshClient.PostAsync("/api/auth/refresh", content, cancellationToken);
        refreshResponse.EnsureSuccessStatusCode();
        var body = await refreshResponse.Content.ReadAsStringAsync(cancellationToken);
        return JsonSerializer.Deserialize<AuthTokensDto>(body, JsonConfig.Options)
            ?? throw new JsonException("Empty token refresh response.");
    }

    private static async Task<HttpRequestMessage> CloneRequest(HttpRequestMessage request)
    {
        var clone = new HttpRequestMessage(request.Method, request.RequestUri);
        if (request.Content != null)
        {
            var body = await request.Content.ReadAsByteArrayAsync();
            clone.Content = new ByteArrayContent(body);
            if (request.Content.Headers.ContentType != null)
                clone.Content.Headers.ContentType = request.Content.Headers.ContentType;
        }
        foreach (var header in request.Headers)
            clone.Headers.TryAddWithoutValidation(header.Key, header.Value);
        return clone;
    }
}
