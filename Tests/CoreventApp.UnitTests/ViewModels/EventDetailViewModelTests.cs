using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.ViewModels;
using Moq;
using RichardSzalay.MockHttp;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.ViewModels;

public class EventDetailViewModelTests
{
    private readonly EventDetailViewModel _vm;

    public EventDetailViewModelTests()
    {
        var httpMock = new MockHttpMessageHandler();
        var client = httpMock.ToHttpClient();
        client.BaseAddress = new Uri("https://api.corevent.com");

        var eventsApiMock = new Mock<IEventsApi>();

        var attrApiMock = new Mock<IAttractionsApi>();

        var favApiMock = new Mock<IFavoritesApi>();
        var favService = new FavoritesService(favApiMock.Object);

        var ratingsApiMock = new Mock<IEventRatingsApi>();

        _vm = new EventDetailViewModel(eventsApiMock.Object, attrApiMock.Object, favService, ratingsApiMock.Object, new CoreventApp.Services.DialogService());
    }

    [Fact]
    public void InitialState_ShouldHaveDefaultValues()
    {
        _vm.EventName.ShouldBeEmpty();
        _vm.Category.ShouldBeEmpty();
        _vm.Location.ShouldBeEmpty();
        _vm.Description.ShouldBeEmpty();
        _vm.HasDescription.ShouldBeFalse();
        _vm.HasAverageRating.ShouldBeFalse();
        _vm.AverageRatingDisplay.ShouldBeEmpty();
        _vm.HasRated.ShouldBeFalse();
        _vm.Star1Filled.ShouldBeFalse();
        _vm.Star5Filled.ShouldBeFalse();
        _vm.IsLoading.ShouldBeFalse();
    }

    [Fact]
    public void Description_ShouldToggleHasDescription()
    {
        _vm.Description = "Detalhes do evento";
        _vm.HasDescription.ShouldBeTrue();

        _vm.Description = "";
        _vm.HasDescription.ShouldBeFalse();
    }

    [Fact]
    public void AverageRating_ShouldFormatDisplayCorrectly()
    {
        _vm.AverageRating = 4.75;
        _vm.HasAverageRating.ShouldBeTrue();
        _vm.AverageRatingDisplay.ShouldBe("4,8");

        _vm.AverageRating = 0;
        _vm.HasAverageRating.ShouldBeFalse();
        _vm.AverageRatingDisplay.ShouldBeEmpty();
    }

    [Fact]
    public void UserRating_ShouldUpdateStarFilledProperties()
    {
        _vm.UserRating = 3;

        _vm.HasRated.ShouldBeTrue();
        _vm.Star1Filled.ShouldBeTrue();
        _vm.Star2Filled.ShouldBeTrue();
        _vm.Star3Filled.ShouldBeTrue();
        _vm.Star4Filled.ShouldBeFalse();
        _vm.Star5Filled.ShouldBeFalse();

        _vm.UserRating = 5;
        _vm.Star5Filled.ShouldBeTrue();

        _vm.UserRating = 0;
        _vm.HasRated.ShouldBeFalse();
        _vm.Star1Filled.ShouldBeFalse();
    }

    [Fact]
    public void Properties_ShouldUpdateCorrectly()
    {
        _vm.EventName = "Festival de Jazz";
        _vm.Category = "Música";
        _vm.Location = "Parque Ibirapuera";
        _vm.Price = "A partir de R$ 50,00";
        _vm.OrganizerName = "Produções Culturais";

        _vm.EventName.ShouldBe("Festival de Jazz");
        _vm.Category.ShouldBe("Música");
        _vm.Location.ShouldBe("Parque Ibirapuera");
        _vm.Price.ShouldBe("A partir de R$ 50,00");
        _vm.OrganizerName.ShouldBe("Produções Culturais");
    }
}
