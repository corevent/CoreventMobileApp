using System.Net;
using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class PaymentInfoApiIntegrationTests
{
    private static IPaymentInfoApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IPaymentInfoApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task GetAllAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":10}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/users/me/organizer-payment-info?page=1&limit=50")
            .Respond("application/json", json);

        var api = CreateApi(httpMock);

        var result = await api.GetAllAsync(1, 50);

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task DeleteAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Delete, "https://api.corevent.com/api/users/me/organizer-payment-info/pi_1")
            .Respond(HttpStatusCode.OK);

        var api = CreateApi(httpMock);

        await api.DeleteAsync("pi_1");

        httpMock.VerifyNoOutstandingExpectation();
    }
}
