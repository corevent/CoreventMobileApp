using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class CheckInApiIntegrationTests
{
    [Fact]
    public async Task CheckinAsync_ShouldSerializeBodyLikeManualClient()
    {
        string? capturedBody = null;
        var httpMock = new MockHttpMessageHandler();
        httpMock.When(HttpMethod.Post, "https://api.corevent.com/api/events/evt_1/checkin")
            .Respond(async req =>
            {
                capturedBody = req.Content is null ? null : await req.Content.ReadAsStringAsync();
                return new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent("{\"data\":null}", Encoding.UTF8, "application/json")
                };
            });

        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        var api = RestService.For<ICheckInApi>(httpClient, RefitConfig.CreateSettings());

        var dto = new CheckinDto("qr_123");
        await api.CheckinAsync("evt_1", dto);

        capturedBody.ShouldBe(JsonSerializer.Serialize(dto, JsonConfig.Options));
    }
}
