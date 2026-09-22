using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class EventTeamViewModelTests
{
    private readonly EventTeamViewModel _vm;

    public EventTeamViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var staffApiMock = new Mock<IEventStaffApi>();
        var invitesApiMock = new Mock<IStaffInvitesApi>();

        _vm = new EventTeamViewModel(staffApiMock.Object, invitesApiMock.Object, new CoreventApp.Services.DialogService());
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.EventName.ShouldBeEmpty();
        _vm.EventStatus.ShouldBeEmpty();
        _vm.InviteEmail.ShouldBeEmpty();
        _vm.SelectedRole.ShouldBe("Credenciamento");
        _vm.IsLoading.ShouldBeFalse();
        _vm.EditingMember.ShouldBeNull();
    }

    [Fact]
    public void CanInvite_ShouldBeTrueOnlyWhenEventIsOpened()
    {
        _vm.EventStatus = "draft";
        _vm.CanInvite.ShouldBeFalse();

        _vm.EventStatus = "opened";
        _vm.CanInvite.ShouldBeTrue();

        _vm.EventStatus = "canceled";
        _vm.CanInvite.ShouldBeFalse();
    }

    [Fact]
    public void TeamMember_Initial_ShouldComputeFromFirstLetterOfNameOrEmail()
    {
        var member1 = new TeamMember { Name = "Mariana Silva", Email = "mariana@test.com" };
        member1.Initial.ShouldBe("M");

        var member2 = new TeamMember { Name = "", Email = "pedro@test.com" };
        member2.Initial.ShouldBe("P");

        var member3 = new TeamMember { Name = "", Email = "" };
        member3.Initial.ShouldBe("?");
    }
}
