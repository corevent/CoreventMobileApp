using CoreventApp.Models;
using CoreventApp.Services;
using CoreventApp.ViewModels;
using Moq;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class ProfileViewModelTests
{
    private readonly Mock<IAuthService> _authMock;

    public ProfileViewModelTests()
    {
        _authMock = new Mock<IAuthService>();
    }

    [Fact]
    public void InitialState_ShouldLoadFromCachedUser_WhenUserIsCached()
    {
        var user = new User
        {
            Id = "u_test",
            Name = "Lucas Dev",
            Email = "lucas@test.com",
            AvatarUrl = "https://cdn.example.com/avatar.png",
            BirthDate = "1995-05-15"
        };
        _authMock.SetupGet(x => x.CurrentCachedUser).Returns(user);

        var vm = new ProfileViewModel(_authMock.Object);

        vm.UserName.ShouldBe("Lucas Dev");
        vm.UserEmail.ShouldBe("lucas@test.com");
        vm.UserAvatar.ShouldBe("https://cdn.example.com/avatar.png");
        vm.IsAdult.ShouldBeTrue();
    }
}
