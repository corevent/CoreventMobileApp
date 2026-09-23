namespace CoreventApp.Models.Dtos;

// States & Cities
public record StateDataDto(int Id, string Name, string Uf);
public record StateResponseDto(List<StateDataDto> Data);
public record CityDataDto(int Id, string Name, int StateId);
public record CityResponseDto(List<CityDataDto> Data);

// Events - List item (from ListEventsDto)
public record EventListItemDto(
    string Id,
    string Title,
    int MaxParticipants,
    string? CityName,
    string? StateAcronym,
    string LocationName,
    DateTime StartDate,
    DateTime EndDate,
    string Category,
    bool IsAdultOnly,
    string Status,
    OrganizerInfoDto Organizer,
    string? LocationType,
    double? AverageRating = null,
    string? FavoriteId = null,
    string? BannerUrl = null);

// Organizer info inside list item
public record OrganizerInfoDto(string Id, string Name, string Email, string? AvatarUrl);

// Pagination
public record PaginationMetaDto(int TotalItems, int TotalPages, int Page, int Limit);

public record EventListPageDto(List<EventListItemDto> Data, PaginationMetaDto Meta);

// Events - Single event detail
public record EventDetailDto(
    string Id,
    string Title,
    string? Description,
    int MaxParticipants,
    string? LocationType,
    string LocationName,
    int? CityId,
    string? CityName,
    string? StateAcronym,
    string? ZipCode,
    string? Neighborhood,
    string? Street,
    int? Number,
    string? Complement,
    DateTime StartDate,
    DateTime EndDate,
    string Category,
    string? BannerUrl,
    bool IsAdultOnly,
    string Status,
    string? EventChangesId,
    DateTime? ChangeRefundDeadline,
    OrganizerInfoDto Organizer,
    DateTime? CreatedAt,
    double? AverageRating = null);

public record EventResponseDto(EventDetailDto Data);

// Events - Request DTOs
public record CreateEventDto(
    string Title,
    string? Description,
    int MaxParticipants,
    string LocationType,
    string? LocationName,
    int? CityId,
    string? ZipCode,
    string? Neighborhood,
    string? Street,
    int? Number,
    string? Complement,
    DateTime StartDate,
    DateTime EndDate,
    string Category,
    bool IsAdultOnly,
    string Status);

public record UpdateEventDto(
    string? Title,
    string? Description,
    int? MaxParticipants,
    string? LocationType,
    string? LocationName,
    int? CityId,
    string? ZipCode,
    string? Neighborhood,
    string? Street,
    int? Number,
    string? Complement,
    DateTime? StartDate,
    DateTime? EndDate,
    string? Category,
    bool? IsAdultOnly,
    string? Status);

public record UpdateEventStatusDto(string Status);
