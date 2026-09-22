using CoreventApp.Models;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class EditProfileViewModelTests
{
    private readonly Mock<IAuthService> _authMock;
    private readonly StorageService _storageService;

    public EditProfileViewModelTests()
    {
        _authMock = new Mock<IAuthService>();

        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var storageApi = Refit.RestService.For<IStorageApi>(client, RefitConfig.CreateSettings());
        _storageService = new StorageService(storageApi);
    }

    [Fact]
    public void InitialState_ShouldLoadFromCachedUser_WhenUserExists()
    {
        var user = new User
        {
            Id = "u_1",
            Name = "Lucas Souza",
            PhoneNumber = "11988887777",
            AvatarUrl = "https://cdn.example.com/avatar.jpg"
        };
        _authMock.SetupGet(x => x.CurrentCachedUser).Returns(user);

        var vm = new EditProfileViewModel(_authMock.Object, _storageService);

        vm.UserName.ShouldBe("Lucas Souza");
        vm.UserPhone.ShouldBe("11988887777");
        vm.UserAvatar.ShouldBe("https://cdn.example.com/avatar.jpg");
        vm.IsBusy.ShouldBeFalse();
    }
}
