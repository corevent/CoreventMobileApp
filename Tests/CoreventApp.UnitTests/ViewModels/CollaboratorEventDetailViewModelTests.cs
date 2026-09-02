using CoreventApp.ViewModels;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class CollaboratorEventDetailViewModelTests
{
    [Fact]
    public void SettingCredenciamentoRole_ShouldSetFlagsAndDescription()
    {
        var vm = new CollaboratorEventDetailViewModel();

        vm.EventRole = "CREDENCIAMENTO";

        vm.IsCredenciamento.ShouldBeTrue();
        vm.AccessNoteDescription.ShouldContain("permissão para realizar o credenciamento");
    }

    [Fact]
    public void SettingOrganizacaoRole_ShouldSetFlagsAndDescription()
    {
        var vm = new CollaboratorEventDetailViewModel();

        vm.EventRole = "ORGANIZAÇÃO";

        vm.IsCredenciamento.ShouldBeFalse();
        vm.AccessNoteDescription.ShouldContain("gerenciar a equipe do evento");
    }
}
