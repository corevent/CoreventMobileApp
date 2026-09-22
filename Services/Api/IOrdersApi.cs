using CoreventApp.Models.Dtos;
using Refit;

namespace CoreventApp.Services.Api;

public interface IOrdersApi
{
    [Post("/api/events/{eventId}/orders")]
    Task<OrderResponseDto> CreateAsync(string eventId, [Body] CreateOrderDto dto);

    [Get("/api/events/my/orders")]
    Task<PaginateMyOrdersDto> GetMyOrdersAsync(int page = 1, int limit = 20);

    [Get("/api/events/orders/{orderId}")]
    Task<OrderDetailsResponseDto> GetByIdAsync(string orderId);
}
