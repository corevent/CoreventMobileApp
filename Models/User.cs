using System.Text.Json.Serialization;
using CoreventApp.Models.Dtos;

namespace CoreventApp.Models;

public class User
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string CPF { get; set; } = string.Empty;
    public string BirthDate { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string AvatarUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    [JsonIgnore]
    public bool IsAdult
    {
        get
        {
            if (!DateOnly.TryParse(BirthDate, out var birth)) return true;
            var today = DateOnly.FromDateTime(DateTime.Today);
            var age = today.Year - birth.Year;
            if (birth > today.AddYears(-age)) age--;
            return age >= 18;
        }
    }

    public static User FromUserDataDto(UserDataDto dto) => new()
    {
        Id = dto.Id,
        Name = dto.Name,
        Email = dto.Email,
        CPF = dto.Cpf,
        BirthDate = dto.BirthDate,
        PhoneNumber = dto.PhoneNumber,
        AvatarUrl = dto.AvatarUrl,
        CreatedAt = dto.CreatedAt
    };
}
