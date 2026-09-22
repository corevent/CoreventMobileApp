using System.Reflection;
using Refit;

namespace CoreventApp.Services.Api;

/// <summary>
/// Formats query parameter values the way the Corevent API expects:
/// bools as lowercase "true"/"false" and dates as "yyyy-MM-dd".
/// TicketTypes endpoints need full timestamps — use [Query(Format = ...)]
/// on those methods instead of relying on this formatter.
/// </summary>
public sealed class CoreventUrlFormatter : DefaultUrlParameterFormatter
{
    public override string? Format(object? value, ICustomAttributeProvider attributeProvider, Type type)
    {
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
