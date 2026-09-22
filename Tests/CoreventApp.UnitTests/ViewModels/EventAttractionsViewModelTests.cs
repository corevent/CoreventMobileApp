using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class EventAttractionsViewModelTests
{
    private readonly EventAttractionsViewModel _vm;

    public EventAttractionsViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var attrApiMock = new Mock<IAttractionsApi>();

        var eventsApiMock = new Mock<IEventsApi>();

        _vm = new EventAttractionsViewModel(attrApiMock.Object, eventsApiMock.Object);
    }

    [Fact]
    public void InitialState_ShouldBeAddingMode()
    {
        _vm.IsEditing.ShouldBeFalse();
        _vm.FormTitle.ShouldBe("Adicionar Atração");
        _vm.FormButtonText.ShouldBe("Adicionar");
        _vm.NewTitle.ShouldBeEmpty();
        _vm.NewGuest.ShouldBeEmpty();
        _vm.IsLoading.ShouldBeFalse();
        _vm.HasAttractions.ShouldBeFalse();
    }

    [Fact]
    public void SettingEditingAttractionId_ShouldSwitchToEditMode()
    {
        _vm.EditingAttractionId = "att_999";

        _vm.IsEditing.ShouldBeTrue();
        _vm.FormTitle.ShouldBe("Editar Atração");
        _vm.FormButtonText.ShouldBe("Salvar");
    }

    [Fact]
    public void Attraction_FormattedTimeRange_ShouldFormatSameDayCorrectly()
    {
        var attraction = new Attraction
        {
            Id = "att_1",
            Title = "Show de Abertura",
            Guest = "Banda X",
            StartDate = new DateTime(2026, 10, 10, 20, 0, 0),
            EndDate = new DateTime(2026, 10, 10, 22, 0, 0)
        };

        attraction.Title.ShouldBe("Show de Abertura");
        attraction.Guest.ShouldBe("Banda X");
        attraction.FormattedTimeRange.ShouldBe("10/10 20:00 - 22:00");
    }

    [Fact]
    public void Attraction_FormattedTimeRange_ShouldFormatDifferentDaysCorrectly()
    {
        var attraction = new Attraction
        {
            Id = "att_2",
            Title = "Virada Musical",
            Guest = "DJ Y",
            StartDate = new DateTime(2026, 10, 10, 23, 0, 0),
            EndDate = new DateTime(2026, 10, 11, 4, 0, 0)
        };

        attraction.FormattedTimeRange.ShouldBe("10/10 23:00 - 11/10 04:00");
    }
}
