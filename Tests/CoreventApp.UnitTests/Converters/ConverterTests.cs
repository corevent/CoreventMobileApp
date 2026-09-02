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
    [InlineData(1, "1", true)]
    [InlineData(2, "2", true)]
    [InlineData(1, "2", false)]
    [InlineData(0, "1", false)]
    [InlineData(null, "1", false)]
    [InlineData(1, null, false)]
    [InlineData(1, "invalid_number", false)]
    public void IntegerToVisibilityConverter_ShouldConvertCorrectly(object? value, object? param, bool expected)
    {
        var converter = new IntegerToVisibilityConverter();
        var result = converter.Convert(value, typeof(bool), param, CultureInfo.InvariantCulture);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData(true, false)]
    [InlineData(false, true)]
    [InlineData(null, false)]
    [InlineData("not_a_bool", false)]
    public void InvertedBoolConverter_ShouldInvertCorrectly(object? input, bool expected)
    {
        var converter = new InvertedBoolConverter();
        var result = converter.Convert(input, typeof(bool), null, CultureInfo.InvariantCulture);
        result.ShouldBe(expected);

        var backResult = converter.ConvertBack(input, typeof(bool), null, CultureInfo.InvariantCulture);
        backResult.ShouldBe(expected);
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

    [Theory]
    [InlineData(null, false)]
    [InlineData("", false)]
    [InlineData("hello", true)]
    [InlineData(0, false)]
    [InlineData(5, true)]
    [InlineData(true, true)]
    public void NotNullToVisibilityConverter_ShouldConvertCorrectly(object? input, bool expected)
    {
        var converter = new NotNullToVisibilityConverter();
        var result = converter.Convert(input, typeof(bool), null, CultureInfo.InvariantCulture);
        result.ShouldBe(expected);
    }
}
