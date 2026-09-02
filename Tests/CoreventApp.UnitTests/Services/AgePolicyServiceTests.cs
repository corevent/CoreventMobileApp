using System.Net;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class AgePolicyServiceTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly AgePoliciesApiClient _api;
    private readonly AgePolicyService _service;

    public AgePolicyServiceTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var httpClient = _httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");

        _api = new AgePoliciesApiClient(httpClient);
        _service = new AgePolicyService(_api);
    }

    [Fact]
    public async Task GetActivePolicyAsync_ShouldReturnPolicy_OnSuccess()
    {
        var json = "{\"data\":{\"id\":\"ap_1\",\"description\":\"Termos 18+\",\"version\":1.0,\"isActive\":true}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/age-policies")
            .Respond("application/json", json);

        var result = await _service.GetActivePolicyAsync();

        result.ShouldNotBeNull();
        result.Id.ShouldBe("ap_1");
        result.Description.ShouldBe("Termos 18+");
        result.IsActive.ShouldBeTrue();
    }

    [Fact]
    public async Task CheckIfUserHasAcceptedAsync_ShouldReturnStatus()
    {
        var json = "{\"data\":{\"userHasAccepted\":true}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/age-policies/acceptances/check")
            .Respond("application/json", json);

        var accepted = await _service.CheckIfUserHasAcceptedAsync();

        accepted.ShouldBeTrue();
    }

    [Fact]
    public async Task AcceptAgePolicyAsync_ShouldReturnTrue_OnSuccess()
    {
        var json = "{\"data\":{\"id\":\"apa_1\",\"userId\":\"u1\",\"agePolicyId\":\"ap_1\",\"createdAt\":\"2026-09-01T00:00:00.000Z\"}}";

        _httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/age-policies/acceptances")
            .Respond("application/json", json);

        var success = await _service.AcceptAgePolicyAsync();

        success.ShouldBeTrue();
    }
}
