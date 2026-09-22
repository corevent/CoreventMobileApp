using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IPaymentInfoApi
{
    [Post("/api/users/me/organizer-payment-info")]
    Task<OrganizerPaymentInfoResDto> CreateAsync([Body] CreateOrganizerPaymentInfoDto dto);

    [Get("/api/users/me/organizer-payment-info")]
    Task<OrganizerPaymentInfoPageDto> GetAllAsync(int page = 1, int limit = 10);

    [Get("/api/users/me/organizer-payment-info/{id}")]
    Task<OrganizerPaymentInfoResDto> GetByIdAsync(string id);

    [Patch("/api/users/me/organizer-payment-info/{id}")]
    Task<OrganizerPaymentInfoResDto> UpdateAsync(string id, [Body] UpdateOrganizerPaymentInfoDto dto);

    [Delete("/api/users/me/organizer-payment-info/{id}")]
    Task DeleteAsync(string id);
}
