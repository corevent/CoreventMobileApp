using System.Net.Mail;
using System.Text.RegularExpressions;

namespace CoreventApp.Helpers;

public static partial class ValidationHelper
{
    public static bool IsValidCpf(string? cpf)
    {
        if (string.IsNullOrWhiteSpace(cpf))
            return false;

        var digits = Regex.Replace(cpf, @"\D", "");

        if (digits.Length != 11)
            return false;

        if (digits.All(c => c == digits[0]))
            return false;

        var numbers = digits.Select(c => c - '0').ToArray();

        var sum1 = 0;
        for (var i = 0; i < 9; i++)
            sum1 += numbers[i] * (10 - i);
        var digit1 = sum1 % 11;
        digit1 = digit1 < 2 ? 0 : 11 - digit1;

        if (numbers[9] != digit1)
            return false;

        var sum2 = 0;
        for (var i = 0; i < 10; i++)
            sum2 += numbers[i] * (11 - i);
        var digit2 = sum2 % 11;
        digit2 = digit2 < 2 ? 0 : 11 - digit2;

        return numbers[10] == digit2;
    }

    public static bool IsValidCnpj(string? cnpj)
    {
        if (string.IsNullOrWhiteSpace(cnpj))
            return false;

        var digits = Regex.Replace(cnpj, @"\D", "");

        if (digits.Length != 14)
            return false;

        if (digits.All(c => c == digits[0]))
            return false;

        var numbers = digits.Select(c => c - '0').ToArray();

        var sum1 = 0;
        var weight1 = new[] { 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };
        for (var i = 0; i < 12; i++)
            sum1 += numbers[i] * weight1[i];
        var digit1 = sum1 % 11;
        digit1 = digit1 < 2 ? 0 : 11 - digit1;

        if (numbers[12] != digit1)
            return false;

        var sum2 = 0;
        var weight2 = new[] { 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };
        for (var i = 0; i < 13; i++)
            sum2 += numbers[i] * weight2[i];
        var digit2 = sum2 % 11;
        digit2 = digit2 < 2 ? 0 : 11 - digit2;

        return numbers[13] == digit2;
    }

    [GeneratedRegex(@"^(\+55)?(\(?\d{2}\)?)[\s-]?(9\d{4}|\d{4})-?\d{4}$")]
    private static partial Regex PhoneRegex();

    public static bool IsValidPhone(string? phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
            return false;

        return PhoneRegex().IsMatch(phone.Trim());
    }

    public static bool IsValidEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;

        try
        {
            var addr = new MailAddress(email);
            return addr.Address == email;
        }
        catch (FormatException)
        {
            return false;
        }
    }

    public static bool IsValidPassword(string? password)
    {
        if (string.IsNullOrWhiteSpace(password) || password.Length < 8)
            return false;

        if (!password.Any(char.IsUpper))
            return false;

        if (!password.Any(char.IsLower))
            return false;

        if (!password.Any(char.IsDigit))
            return false;

        if (!password.Any(static c => !char.IsLetterOrDigit(c)))
            return false;

        return true;
    }
}
