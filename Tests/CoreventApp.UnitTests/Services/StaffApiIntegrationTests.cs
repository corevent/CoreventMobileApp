using System.Net;
using CoreventApp.Services.Api;
using Refit;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class StaffApiIntegrationTests
{
    private static IEventStaffApi CreateStaffApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IEventStaffApi>(httpClient, RefitConfig.CreateSettings());
    }

    private static IStaffInvitesApi CreateInvitesApi(MockHttpMessageHandler httpMock)
    {
        var httpClient = httpMock.ToHttpClient();
        httpClient.BaseAddress = new Uri("https://api.corevent.com");
        return RestService.For<IStaffInvitesApi>(httpClient, RefitConfig.CreateSettings());
    }

    [Fact]
    public async Task StaffGetAllAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":10}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/events/evt_1/staff?page=1&limit=10")
            .Respond("application/json", json);

        var api = CreateStaffApi(httpMock);

        var result = await api.GetAllAsync("evt_1");

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task InvitesGetAllAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":10}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/invitations/events/evt_1?page=1&limit=10&invitationStatus=pending")
            .Respond("application/json", json);

        var api = CreateInvitesApi(httpMock);

        var result = await api.GetAllAsync("evt_1", "pending");

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task AcceptAsync_ShouldPostWithoutBody()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Post, "https://api.corevent.com/api/invitations/inv_1/accept")
            .Respond("application/json", "{\"data\":null}");

        var api = CreateInvitesApi(httpMock);

        await api.AcceptAsync("inv_1");

        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task GetMyInvitationsAsync_ShouldCallCorrectRoute()
    {
        var json = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":10}}";
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/invitations/me?page=1&limit=10&invitationStatus=pending")
            .Respond("application/json", json);

        var api = CreateInvitesApi(httpMock);

        var result = await api.GetMyInvitationsAsync(invitationStatus: "pending");

        result.Data.ShouldBeEmpty();
        httpMock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task UpdateAccessLevelAsync_ShouldCallCorrectRoute()
    {
        var httpMock = new MockHttpMessageHandler();
        httpMock.Expect(new HttpMethod("PATCH"), "https://api.corevent.com/api/events/st_1/access-level")
            .Respond("application/json", "{\"data\":null}");

        var api = CreateStaffApi(httpMock);

        await api.UpdateAccessLevelAsync("st_1", new CoreventApp.Models.Dtos.UpdateEventStaffAccessLevelDto("checkin"));

        httpMock.VerifyNoOutstandingExpectation();
    }
}
