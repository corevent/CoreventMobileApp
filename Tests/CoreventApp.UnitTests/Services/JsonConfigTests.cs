using System.Text.Json;
using CoreventApp.Services.Api;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Services;

public class JsonConfigTests
{
    private record SampleDto(string UserName, int ItemCount, DateTime CreatedAt);

    [Fact]
    public void JsonConfigOptions_ShouldSerializeWithCamelCase()
    {
        var dto = new SampleDto("Lucas", 5, new DateTime(2026, 9, 1, 12, 0, 0, DateTimeKind.Utc));

        var json = JsonSerializer.Serialize(dto, JsonConfig.Options);

        json.ShouldContain("\"userName\":\"Lucas\"");
        json.ShouldContain("\"itemCount\":5");
        json.ShouldContain("\"createdAt\":\"2026-09-01T12:00:00.000Z\"");
    }

    [Fact]
    public void JsonConfigOptions_ShouldDeserializeFromStringNumbers()
    {
        var json = "{\"userName\":\"Lucas\",\"itemCount\":\"42\",\"createdAt\":\"2026-09-01T12:00:00.000Z\"}";

        var dto = JsonSerializer.Deserialize<SampleDto>(json, JsonConfig.Options);

        dto.ShouldNotBeNull();
        dto.UserName.ShouldBe("Lucas");
        dto.ItemCount.ShouldBe(42);
        dto.CreatedAt.Kind.ShouldBe(DateTimeKind.Utc);
    }

    [Fact]
    public void UtcDateTimeConverter_ShouldEnsureUtcKindOnDeserialization()
    {
        var json = "{\"userName\":\"Test\",\"itemCount\":1,\"createdAt\":\"2026-09-01T15:30:00.000Z\"}";

        var dto = JsonSerializer.Deserialize<SampleDto>(json, JsonConfig.Options);

        dto.ShouldNotBeNull();
        dto.CreatedAt.Kind.ShouldBe(DateTimeKind.Utc);
        dto.CreatedAt.Hour.ShouldBe(15);
        dto.CreatedAt.Minute.ShouldBe(30);
    }
}
