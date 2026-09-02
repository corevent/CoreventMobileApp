using CoreventApp.ViewModels;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class SettingsViewModelTests
{
    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        var vm = new SettingsViewModel();

        vm.IsPushNotificationsEnabled.ShouldBeTrue();
        vm.IsDarkModeEnabled.ShouldBeFalse();
        vm.CurrentLanguage.ShouldBe("Português (BR)");
    }

    [Fact]
    public void Properties_ShouldUpdateCorrectly()
    {
        var vm = new SettingsViewModel();

        vm.IsPushNotificationsEnabled = false;
        vm.IsDarkModeEnabled = true;
        vm.CurrentLanguage = "English";

        vm.IsPushNotificationsEnabled.ShouldBeFalse();
        vm.IsDarkModeEnabled.ShouldBeTrue();
        vm.CurrentLanguage.ShouldBe("English");
    }
}
