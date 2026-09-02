using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class UserInvitationsViewModelTests
{
    private readonly MockHttpMessageHandler _httpMock;
    private readonly UserInvitationsViewModel _vm;

    public UserInvitationsViewModelTests()
    {
        _httpMock = new MockHttpMessageHandler();
        var client = _httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var api = new StaffInvitesApiClient(client);
        _vm = new UserInvitationsViewModel(api);
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.PendingInvitations.ShouldBeEmpty();
        _vm.AcceptedInvitations.ShouldBeEmpty();
        _vm.RejectedInvitations.ShouldBeEmpty();
        _vm.HasInvitations.ShouldBeFalse();
        _vm.HasPending.ShouldBeFalse();
        _vm.HasAccepted.ShouldBeFalse();
        _vm.HasRejected.ShouldBeFalse();
        _vm.IsLoading.ShouldBeFalse();
        _vm.IsRefreshing.ShouldBeFalse();
    }

    [Fact]
    public async Task LoadInvitationsAsync_ShouldCategorizePendingAcceptedRejected()
    {
        var org = new UserInfoDto("u1", "Lucas Org", "lucas@test.com", null);
        var eventRef = new EventRefDto("evt_1", "Tech Summit 2026", org);

        var pendingJson = "{\"data\":[{\"id\":\"inv_1\",\"userId\":\"u2\",\"event\":{\"id\":\"evt_1\",\"title\":\"Tech Summit 2026\",\"organizer\":{\"id\":\"u1\",\"name\":\"Lucas Org\",\"email\":\"lucas@test.com\",\"avatarUrl\":null}},\"originalAccessLevel\":\"checkin\",\"invitationStatus\":\"pending\",\"createdAt\":\"2026-09-01T00:00:00.000Z\"}],\"meta\":{\"totalItems\":1,\"totalPages\":1,\"page\":1,\"limit\":50}}";
        var acceptedJson = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":50}}";
        var rejectedJson = "{\"data\":[],\"meta\":{\"totalItems\":0,\"totalPages\":0,\"page\":1,\"limit\":50}}";

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/invitations/me*invitationStatus=pending*")
            .Respond("application/json", pendingJson);

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/invitations/me*invitationStatus=accepted*")
            .Respond("application/json", acceptedJson);

        _httpMock.Expect(HttpMethod.Get, "https://api.corevent.com/api/invitations/me*invitationStatus=rejected*")
            .Respond("application/json", rejectedJson);

        await _vm.LoadInvitationsCommand.ExecuteAsync(null);

        _vm.PendingInvitations.Count.ShouldBe(1);
        _vm.PendingInvitations[0].EventName.ShouldBe("Tech Summit 2026");
        _vm.PendingInvitations[0].OrganizerName.ShouldBe("Lucas Org");
        _vm.PendingInvitations[0].Role.ShouldBe("Credenciamento");
        _vm.PendingInvitations[0].IsPending.ShouldBeTrue();

        _vm.HasPending.ShouldBeTrue();
        _vm.HasInvitations.ShouldBeTrue();
    }

    [Fact]
    public void UserInvitationItem_Properties_ShouldMapCorrectly()
    {
        var org = new UserInfoDto("u1", "Ana Costa", "ana@test.com", null);
        var eventRef = new EventRefDto("e1", "Festival Jazz", org);
        var dto = new UserInvitationDto("inv_10", "u2", eventRef, "checkin", "pending", DateTime.UtcNow);

        var item = new UserInvitationItem(dto);

        item.Id.ShouldBe("inv_10");
        item.EventName.ShouldBe("Festival Jazz");
        item.OrganizerName.ShouldBe("Ana Costa");
        item.Role.ShouldBe("Credenciamento");
        item.Status.ShouldBe("Pendente");
        item.IsPending.ShouldBeTrue();
        item.EventInitial.ShouldBe("F");
    }
}
