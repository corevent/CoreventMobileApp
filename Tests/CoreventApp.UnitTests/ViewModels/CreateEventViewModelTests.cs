using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class CreateEventViewModelTests
{
    private readonly CreateEventViewModel _vm;

    public CreateEventViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApiMock = new Mock<IEventsApi>();
        var statesApiMock = new Mock<IStatesApi>();
        var paymentInfoApi = Refit.RestService.For<IPaymentInfoApi>(client, RefitConfig.CreateSettings());
        var paymentInfoService = new PaymentInfoService(paymentInfoApi);
        var storageApi = Refit.RestService.For<IStorageApi>(client, RefitConfig.CreateSettings());
        var storageService = new StorageService(storageApi);

        _vm = new CreateEventViewModel(eventsApiMock.Object, statesApiMock.Object, paymentInfoService, storageService, new CoreventApp.Services.DialogService());
    }

    [Fact]
    public void InitialState_ShouldBeOnStep1WithDefaultSettings()
    {
        _vm.CurrentStep.ShouldBe(1);
        _vm.Progress.ShouldBe(0.33);
        _vm.PageTitle.ShouldBe("Criar Evento");
        _vm.StepTitle.ShouldBe("Informações Básicas");
        _vm.ButtonNextText.ShouldBe("Próximo");
        _vm.Form.ShouldNotBeNull();
        _vm.IsEditing.ShouldBeFalse();
        _vm.IsEditable.ShouldBeTrue();
        _vm.ShowDraftButton.ShouldBeTrue();
        _vm.ShowPublishButton.ShouldBeTrue();
        _vm.DraftButtonText.ShouldBe("Salvar Rascunho");
        _vm.Categories.ShouldNotBeEmpty();
        _vm.LocationTypes.ShouldNotBeEmpty();
    }

    [Fact]
    public async Task WizardStepNavigation_ShouldAdvanceAndGoBack()
    {
        _vm.Form.Title = "Workshop de .NET MAUI 2026";
        _vm.Form.Category = "Tecnologia";
        _vm.Form.StartDate = DateTime.Now.AddDays(5);
        _vm.Form.EndDate = DateTime.Now.AddDays(6);
        _vm.Form.States.Add(new StateDataDto(1, "São Paulo", "SP"));

        await _vm.NextCommand.ExecuteAsync(null);
        _vm.CurrentStep.ShouldBe(2);
        _vm.StepTitle.ShouldBe("Data e Participação");

        await _vm.NextCommand.ExecuteAsync(null);
        _vm.CurrentStep.ShouldBe(3);
        _vm.StepTitle.ShouldBe("Localização");
        _vm.ButtonNextText.ShouldBe("Criar Evento");

        await _vm.BackCommand.ExecuteAsync(null);
        _vm.CurrentStep.ShouldBe(2);

        await _vm.BackCommand.ExecuteAsync(null);
        _vm.CurrentStep.ShouldBe(1);
    }

    [Fact]
    public void FormProperties_ShouldUpdateCorrectly()
    {
        _vm.Form.Title = "Festival de Verão 2026";
        _vm.Form.Description = "Grande festival com bandas nacionais.";
        _vm.Form.Category = "Música";
        _vm.Form.LocationType = "Presencial";
        _vm.Form.MaxParticipants = 500;
        _vm.Form.IsOver18 = true;
        _vm.Form.LocationName = "Arena Principal";
        _vm.Form.Street = "Av Paulista";
        _vm.Form.Number = "1000";
        _vm.Form.Neighborhood = "Bela Vista";
        _vm.Form.ZipCode = "01310-100";
        _vm.Form.Complement = "Bloco A";

        _vm.Form.Title.ShouldBe("Festival de Verão 2026");
        _vm.Form.Description.ShouldBe("Grande festival com bandas nacionais.");
        _vm.Form.Category.ShouldBe("Música");
        _vm.Form.LocationType.ShouldBe("Presencial");
        _vm.Form.MaxParticipants.ShouldBe(500);
        _vm.Form.IsOver18.ShouldBeTrue();
        _vm.Form.LocationName.ShouldBe("Arena Principal");
        _vm.Form.Street.ShouldBe("Av Paulista");
        _vm.Form.Number.ShouldBe("1000");
        _vm.Form.Neighborhood.ShouldBe("Bela Vista");
        _vm.Form.ZipCode.ShouldBe("01310-100");
        _vm.Form.Complement.ShouldBe("Bloco A");
    }

    [Fact]
    public void TitleError_ShouldDetectEmptyTitle()
    {
        _vm.Form.Title = "";
        _vm.Form.TitleError.ShouldBe("O título é obrigatório.");

        _vm.Form.Title = "Meu Evento";
        _vm.Form.TitleError.ShouldBeNull();
    }

    [Fact]
    public void StartDateError_ShouldDetectPastDatesWhenNotEditing()
    {
        _vm.Form.IsEditingForm = false;
        _vm.Form.StartDate = DateTime.Now.AddDays(-2);
        _vm.Form.StartDateError.ShouldBe("A data de início deve ser no futuro.");

        _vm.Form.StartDate = DateTime.Now.AddDays(10);
        _vm.Form.StartDateError.ShouldBeNull();
    }

    [Fact]
    public void EndDateError_ShouldDetectEndDateBeforeStartDate()
    {
        _vm.Form.StartDate = DateTime.Now.AddDays(10);
        _vm.Form.EndDate = DateTime.Now.AddDays(5);
        _vm.Form.EndDateError.ShouldBe("A data de término não pode ser anterior à data de início.");

        _vm.Form.EndDate = DateTime.Now.AddDays(12);
        _vm.Form.EndDateError.ShouldBeNull();
    }

    [Fact]
    public void LocationType_ShouldTogglePhysicalLocationVisibility()
    {
        _vm.Form.LocationType = "Online";
        _vm.Form.IsPhysicalLocationVisible.ShouldBeFalse();
        _vm.Form.AddressError.ShouldBeNull();

        _vm.Form.LocationType = "Presencial";
        _vm.Form.IsPhysicalLocationVisible.ShouldBeTrue();
    }

    [Fact]
    public void AddressError_ShouldValidateRequiredFieldsForPhysicalLocation()
    {
        _vm.Form.LocationType = "Presencial";
        _vm.Form.Street = "";
        _vm.Form.AddressError.ShouldBe("A rua é obrigatória.");

        _vm.Form.Street = "Rua Teste";
        _vm.Form.Number = "0";
        _vm.Form.AddressError.ShouldBe("Informe um número válido.");

        _vm.Form.Number = "123";
        _vm.Form.Neighborhood = "";
        _vm.Form.AddressError.ShouldBe("O bairro é obrigatório.");

        _vm.Form.Neighborhood = "Centro";
        _vm.Form.ZipCode = "";
        _vm.Form.AddressError.ShouldBe("O CEP é obrigatório.");

        _vm.Form.ZipCode = "12345-000";
        _vm.Form.SelectedCityIndex = -1;
        _vm.Form.AddressError.ShouldBe("Selecione uma cidade.");
    }

    [Fact]
    public void StateAndCityCascadingSelection_ShouldWorkCorrectly()
    {
        var state = new StateDataDto(1, "São Paulo", "SP");
        var city = new CityDataDto(100, "São Paulo", 1);

        _vm.Form.States.Add(state);
        _vm.Form.Cities.Add(city);

        _vm.Form.SelectedStateIndex = 0;
        _vm.Form.SelectedState.ShouldBe(state);

        _vm.Form.SelectedCityIndex = 0;
        _vm.Form.SelectedCityId.ShouldBe(100);
    }
}
