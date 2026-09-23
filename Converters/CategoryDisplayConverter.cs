using System.Globalization;

namespace CoreventApp.Converters;

public class CategoryDisplayConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return CoreventApp.Models.DomainCatalog.CategoryLabel(value as string);
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}
