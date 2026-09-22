using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IStaffInvitesApi
{
    [Post("/api/invitations/events/{eventId}")]
    Task<EventStaffInvitationResponseDto> CreateAsync(string eventId, [Body] CreateEventStaffInvitationDto dto);

    [Get("/api/invitations/events/{eventId}")]
    Task<PaginateEventStaffInvitationsDto> GetAllAsync(
        string eventId,
        string invitationStatus,
        int page = 1,
        int limit = 10);

    [Post("/api/invitations/{invitationId}/accept")]
    Task<EventStaffResponseDto> AcceptAsync(string invitationId);

    [Post("/api/invitations/{invitationId}/reject")]
    Task<MessageDto> RejectAsync(string invitationId);

    [Post("/api/invitations/{invitationId}/cancel")]
    Task<MessageDto> CancelAsync(string invitationId);

    [Get("/api/invitations/me")]
    Task<UserInvitationPageDto> GetMyInvitationsAsync(
        int page = 1, int limit = 10,
        string? name = null,
        string? email = null,
        string invitationStatus = "pending",
        string? originalAccessLevel = null);
}
