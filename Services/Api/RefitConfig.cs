using System.Globalization;
using System.Reflection;
using Refit;

namespace CoreventApp.Services.Api;

/// <summary>
/// Formats query parameter values the way the Corevent API expects:
/// bools as lowercase "true"/"false" and dates as "yyyy-MM-dd".
/// An explicit [Query(Format = ...)] on a parameter always wins
/// (used by TicketTypes endpoints, which need full timestamps).
/// </summary>
public sealed class CoreventUrlFormatter : DefaultUrlParameterFormatter
{
    public override string? Format(object? value, ICustomAttributeProvider attributeProvider, Type type)
    {
        // An explicit [Query(Format = ...)] always wins. Note: with Refit's
        // source generator the provider is not a ParameterInfo, so read the
        // attribute off ICustomAttributeProvider directly.
        if (value is not null)
        {
            var query = attributeProvider.GetCustomAttributes(false)
                .OfType<QueryAttribute>()
                .FirstOrDefault();
            if (query?.Format is not null && value is IFormattable formattable)
                return formattable.ToString(query.Format, CultureInfo.InvariantCulture);
        }

        if (value is bool b)
            return b ? "true" : "false";

        if (value is DateTime dt)
            return dt.ToString("yyyy-MM-dd");

        return base.Format(value, attributeProvider, type);
    }
}

/// <summary>
/// Single place to build the <see cref="RefitSettings"/> used by all Refit clients.
/// Starts from Refit's defaults (camelCase + AllowReadingFromString) and adds the
/// app's <see cref="UtcDateTimeConverter"/> so bodies stay byte-compatible with the
/// previous manual serialization via <see cref="JsonConfig"/>.
/// </summary>
public static class RefitConfig
{
    public static RefitSettings CreateSettings()
    {
        var options = SystemTextJsonContentSerializer.GetDefaultJsonSerializerOptions();
        options.Converters.Add(new UtcDateTimeConverter());

        return new RefitSettings(new SystemTextJsonContentSerializer(options))
        {
            UrlParameterFormatter = new CoreventUrlFormatter()
        };
    }
}
