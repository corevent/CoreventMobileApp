using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IAgePoliciesApi
{
    [Get("/api/age-policies")]
    Task<AgePolicyResponseDto> GetActivePolicyAsync();

    [Get("/api/age-policies/acceptances/check")]
    Task<CheckAcceptanceResponseDto> CheckAcceptanceAsync();

    [Post("/api/age-policies/acceptances")]
    Task<AgePolicyAcceptanceResponseDto> AcceptPolicyAsync();
}
