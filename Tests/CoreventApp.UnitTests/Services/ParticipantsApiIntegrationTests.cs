using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class ParticipantsApiIntegrationTests
{
    [Fact]
    public async Task GetAllAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":100}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/participants?page=1&limit=100")
            .Respond("application/json", json);

        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        var api = RestService.For<IParticipantsApi>(httpClient, RefitConfig.CreateSettings());

        var result = await api.GetAllAsync("evt_1", 1, 100);

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }
}
