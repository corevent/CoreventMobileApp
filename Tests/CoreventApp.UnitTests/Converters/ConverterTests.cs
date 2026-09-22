using System.Globalization;
using CoreventApp.Converters;
using Microsoft.Maui.Controls;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Converters;

public class ConverterTests
{
    [Theory]
    [InlineData("draft", "RASCUNHO")]
    [InlineData("opened", "ATIVO")]
    [InlineData("going", "EM ANDAMENTO")]
    [InlineData("canceled", "CANCELADO")]
    [InlineData("finished", "ENCERRADO")]
    [InlineData("desconhecido", "ATIVO")]
    [InlineData(null, "ATIVO")]
    public void StatusDisplayConverter_ShouldConvertCorrectly(object? input, string expected)
    {
        var converter = new StatusDisplayConverter();
        var result = converter.Convert(input, typeof(string), null, CultureInfo.InvariantCulture);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData("music", "Música")]
    [InlineData("tech", "Tecnologia")]
    [InlineData("education", "Educação")]
    [InlineData("sports", "Esportes")]
    [InlineData("business", "Negócios")]
    [InlineData("art_culture", "Arte e Cultura")]
    [InlineData("gastronomy", "Gastronomia")]
    [InlineData("health_wellness", "Saúde e Bem-estar")]
    [InlineData("family_kids", "Família e Crianças")]
    [InlineData("religious_spiritual", "Religioso/Espiritual")]
    [InlineData("games", "Jogos")]
    [InlineData("community_social", "Comunidade/Social")]
    [InlineData("fashion_beauty", "Moda e Beleza")]
    [InlineData("other", "Outro")]
    [InlineData("custom_category", "custom_category")]
    public void CategoryDisplayConverter_ShouldConvertCorrectly(string category, string expected)
    {
        var converter = new CategoryDisplayConverter();
        var result = converter.Convert(category, typeof(string), null, CultureInfo.InvariantCulture);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData("in_person", "Presencial")]
    [InlineData("online", "Online")]
    [InlineData("hybrid", "Híbrido")]
    [InlineData("unknown", "Presencial")]
    [InlineData(null, "Presencial")]
    public void LocationTypeDisplayConverter_ShouldConvertCorrectly(object? input, string expected)
    {
        var converter = new LocationTypeDisplayConverter();
        var result = converter.Convert(input, typeof(string), null, CultureInfo.InvariantCulture);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData(0, "☆☆☆☆☆")]
    [InlineData(1, "★☆☆☆☆")]
    [InlineData(3, "★★★☆☆")]
    [InlineData(5, "★★★★★")]
    [InlineData(6, "★★★★★")] // Clamped to 5
    [InlineData(-1, "☆☆☆☆☆")] // Clamped to 0
    [InlineData(null, "☆☆☆☆☆")]
    [InlineData("not_an_int", "☆☆☆☆☆")]
    public void RatingToStarsConverter_ShouldFormatStarsCorrectly(object? input, string expected)
    {
        var converter = new RatingToStarsConverter();
        var result = converter.Convert(input, typeof(string), null, CultureInfo.InvariantCulture);
        result.ShouldBe(expected);
    }

}
