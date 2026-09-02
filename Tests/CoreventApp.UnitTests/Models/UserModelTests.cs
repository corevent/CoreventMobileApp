using CoreventApp.Models;
using CoreventApp.Models.Dtos;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Models;

public class UserModelTests
{
    [Fact]
    public void IsAdult_ShouldReturnTrue_WhenAgeIsOver18()
    {
        var birthDate = DateTime.Today.AddYears(-25).ToString("yyyy-MM-dd");
        var user = new User { BirthDate = birthDate };

        user.IsAdult.ShouldBeTrue();
    }

    [Fact]
    public void IsAdult_ShouldReturnTrue_WhenUserTurns18Today()
    {
        var birthDate = DateTime.Today.AddYears(-18).ToString("yyyy-MM-dd");
        var user = new User { BirthDate = birthDate };

        user.IsAdult.ShouldBeTrue();
    }

    [Fact]
    public void IsAdult_ShouldReturnFalse_WhenUserTurns18Tomorrow()
    {
        var birthDate = DateTime.Today.AddYears(-18).AddDays(1).ToString("yyyy-MM-dd");
        var user = new User { BirthDate = birthDate };

        user.IsAdult.ShouldBeFalse();
    }

    [Fact]
    public void IsAdult_ShouldReturnFalse_WhenAgeIsUnder18()
    {
        var birthDate = DateTime.Today.AddYears(-16).ToString("yyyy-MM-dd");
        var user = new User { BirthDate = birthDate };

        user.IsAdult.ShouldBeFalse();
    }

    [Fact]
    public void IsAdult_ShouldReturnTrue_WhenBirthDateIsInvalid()
    {
        var user = new User { BirthDate = "data_invalida" };

        user.IsAdult.ShouldBeTrue();
    }

    [Fact]
    public void FromUserDataDto_ShouldMapAllFieldsCorrectly()
    {
        var now = DateTime.UtcNow;
        var dto = new UserDataDto(
            Id: "usr_123",
            Name: "Lucas Silva",
            Email: "lucas@example.com",
            Cpf: "12345678901",
            BirthDate: "2000-05-15",
            PhoneNumber: "+5511999999999",
            AvatarUrl: "https://example.com/avatar.png",
            CreatedAt: now
        );

        var user = User.FromUserDataDto(dto);

        user.Id.ShouldBe("usr_123");
        user.Name.ShouldBe("Lucas Silva");
        user.Email.ShouldBe("lucas@example.com");
        user.CPF.ShouldBe("12345678901");
        user.BirthDate.ShouldBe("2000-05-15");
        user.PhoneNumber.ShouldBe("+5511999999999");
        user.AvatarUrl.ShouldBe("https://example.com/avatar.png");
        user.CreatedAt.ShouldBe(now);
    }
}
