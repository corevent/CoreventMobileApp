using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class UserInvitationsViewModelTests
{
    private readonly Mock<IStaffInvitesApi> _invitesApiMock;
    private readonly UserInvitationsViewModel _vm;

    public UserInvitationsViewModelTests()
    {
        _invitesApiMock = new Mock<IStaffInvitesApi>();
        _vm = new UserInvitationsViewModel(_invitesApiMock.Object);
    }

    private static UserInvitationPageDto Page(params UserInvitationDto[] items) =>
        new(new List<UserInvitationDto>(items), new PaginationMetaDto(items.Length, 1, 1, 50));

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
        var pending = new UserInvitationDto("inv_1", "u2", eventRef, "checkin", "pending", new DateTime(2026, 9, 1));

        _invitesApiMock.Setup(a => a.GetMyInvitationsAsync(1, 50, null, null, "pending", null))
            .ReturnsAsync(Page(pending));
        _invitesApiMock.Setup(a => a.GetMyInvitationsAsync(1, 50, null, null, "accepted", null))
            .ReturnsAsync(Page());
        _invitesApiMock.Setup(a => a.GetMyInvitationsAsync(1, 50, null, null, "rejected", null))
            .ReturnsAsync(Page());

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
