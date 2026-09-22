using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface ICheckInApi
{
    [Post("/api/events/{eventId}/checkin")]
    Task<CheckinResponseDto> CheckinAsync(string eventId, [Body] CheckinDto dto);
}
