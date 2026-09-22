using System.Net;
using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class AgePoliciesApiIntegrationTests
{
    private static IAgePoliciesApi CreateApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IAgePoliciesApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task CheckAcceptanceAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/age-policies/acceptances/check")
            .Respond("application/json", "{\"data\":{\"userHasAccepted\":true}}");

        var api = CreateApi(httpMock);

        var result = await api.CheckAcceptanceAsync();

        result.Data.UserHasAccepted.ShouldBeTrue();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task AcceptPolicyAsync_ShouldPostWithoutBody()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/age-policies/acceptances")
            .Respond("application/json", "{\"data\":null}");

        var api = CreateApi(httpMock);

        await api.AcceptPolicyAsync();

        httpMock.VerifyNoOutstandingExpectation();
    }
}
