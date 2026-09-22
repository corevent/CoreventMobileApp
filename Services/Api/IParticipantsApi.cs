using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IParticipantsApi
{
    [Get("/api/events/{eventId}/participants")]
    Task<ParticipantListPageDto> GetAllAsync(string eventId, int page = 1, int limit = 100);
}
