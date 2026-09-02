using CoreventApp.Helpers;
using Shouldly;
using Xunit;

namespace CoreventApp.UnitTests.Helpers;

public class ValidationHelperTests
{
    [Theory]
    [InlineData("52998224725", true)]
    [InlineData("529.982.247-25", true)]
    [InlineData("11144477735", true)]
    [InlineData("123.456.789-09", true)]
    [InlineData("123.456.789-00", false)]
    [InlineData("111.111.111-11", false)]
    [InlineData("00000000000", false)]
    [InlineData("123", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void IsValidCpf_ShouldValidateCorrectly(string? cpf, bool expected)
    {
        var result = ValidationHelper.IsValidCpf(cpf);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData("11222333000181", true)]
    [InlineData("11.222.333/0001-81", true)]
    [InlineData("00000000000000", false)]
    [InlineData("11111111111111", false)]
    [InlineData("11.222.333/0001-00", false)]
    [InlineData("123", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void IsValidCnpj_ShouldValidateCorrectly(string? cnpj, bool expected)
    {
        var result = ValidationHelper.IsValidCnpj(cnpj);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData("+5511912345678", true)]
    [InlineData("+55(11)91234-5678", true)]
    [InlineData("(11) 91234-5678", true)]
    [InlineData("11 912345678", true)]
    [InlineData("(11) 3456-7890", true)]
    [InlineData("12345", false)]
    [InlineData("abcdef", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void IsValidPhone_ShouldValidateCorrectly(string? phone, bool expected)
    {
        var result = ValidationHelper.IsValidPhone(phone);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData("user@example.com", true)]
    [InlineData("contato@corevent.com.br", true)]
    [InlineData("invalido@", false)]
    [InlineData("@dominio.com", false)]
    [InlineData("sem-arroba.com", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void IsValidEmail_ShouldValidateCorrectly(string? email, bool expected)
    {
        var result = ValidationHelper.IsValidEmail(email);
        result.ShouldBe(expected);
    }

    [Theory]
    [InlineData("Senha@123", true)]
    [InlineData("Corevent#2026", true)]
    [InlineData("senha123", false)] // Sem maiúscula e sem especial
    [InlineData("SENHA@123", false)] // Sem minúscula
    [InlineData("SenhaForte@", false)] // Sem dígito
    [InlineData("Senha123", false)] // Sem caractere especial
    [InlineData("Ab1!", false)] // Menor que 8 caracteres
    [InlineData("", false)]
    [InlineData(null, false)]
    public void IsValidPassword_ShouldValidateComplexityRules(string? password, bool expected)
    {
        var result = ValidationHelper.IsValidPassword(password);
        result.ShouldBe(expected);
    }
}
