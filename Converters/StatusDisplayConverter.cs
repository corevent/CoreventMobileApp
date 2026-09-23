using System.Globalization;

namespace CoreventApp.Converters;

public class StatusDisplayConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return CoreventApp.Models.DomainCatalog.Status(CoreventApp.Models.StatusKind.Event, value as string).Label;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}
