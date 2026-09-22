using System.Diagnostics;
using CoreventApp.Models.Dtos;
using CoreventApp.Services.Api;

namespace CoreventApp.Services;

public class PaymentInfoService
{
    private readonly IPaymentInfoApi _api;

    public PaymentInfoService(IPaymentInfoApi api)
    {
        _api = api;
    }

    public async Task<OrganizerPaymentInfoDataDto?> CreateAsync(CreateOrganizerPaymentInfoDto dto)
    {
        var result = await ApiResult.TryExecuteAsync(() => _api.CreateAsync(dto), "Create payment info");
        return result?.Data;
    }

    public async Task<List<OrganizerPaymentInfoDataDto>> GetAllAsync()
    {
        var page = await ApiResult.TryExecuteAsync(() => _api.GetAllAsync(1, 50), "Get payment info list");
        if (page is null || page.Data.Count == 0)
            return new List<OrganizerPaymentInfoDataDto>();

        var results = new List<OrganizerPaymentInfoDataDto>();
        foreach (var id in page.Data.Select(x => x.Id))
        {
            var item = await ApiResult.TryExecuteAsync(() => _api.GetByIdAsync(id), "Get payment info");
            if (item is not null)
                results.Add(item.Data);
        }
        return results;
    }

    public async Task<bool> DeleteAsync(string id)
    {
        return await ApiResult.TryExecuteAsync(() => _api.DeleteAsync(id), "Delete payment info");
    }
}
