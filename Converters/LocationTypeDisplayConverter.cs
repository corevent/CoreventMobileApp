using System.Globalization;

namespace CoreventApp.Converters;

public class LocationTypeDisplayConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return CoreventApp.Models.DomainCatalog.LocationTypeLabel(value as string);
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}
