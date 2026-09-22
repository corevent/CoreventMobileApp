using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IStatesApi
{
    [Get("/api/states")]
    Task<StateResponseDto> GetStatesAsync();

    [Get("/api/states/{stateId}/cities")]
    Task<CityResponseDto> GetCitiesAsync(int stateId);
}
