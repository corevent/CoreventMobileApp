import 'package:json_annotation/json_annotation.dart';

part 'activity_dtos.g.dart';

@JsonSerializable(createToJson: false)
class ActivityMeta {
  const ActivityMeta(this.currentPage, this.totalPages);
  final int currentPage;
  final int totalPages;
  factory ActivityMeta.fromJson(Map<String, dynamic> json) =>
      _$ActivityMetaFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderPage {
  const OrderPage(this.data, this.meta);
  final List<BuyerOrder> data;
  final ActivityMeta meta;
  factory OrderPage.fromJson(Map<String, dynamic> json) =>
      _$OrderPageFromJson(json);
}

@JsonSerializable(createToJson: false)
class BuyerOrder {
  const BuyerOrder(
    this.id,
    this.event,
    this.totalAmount,
    this.status,
    this.createdAt,
  );
  final String id;
  final OrderEvent event;
  @JsonKey(fromJson: _readAmount)
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  factory BuyerOrder.fromJson(Map<String, dynamic> json) =>
      _$BuyerOrderFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderEvent {
  const OrderEvent(this.id, this.title, this.startDate);
  final String id;
  final String title;
  final DateTime startDate;
  factory OrderEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderDetailsResponse {
  const OrderDetailsResponse(this.data);
  final OrderDetails data;
  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailsResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderDetails {
  const OrderDetails(
    this.id,
    this.event,
    this.totalAmount,
    this.status,
    this.createdAt,
    this.tickets,
    this.checkout,
  );
  final String id;
  final OrderEvent event;
  @JsonKey(fromJson: _readAmount)
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final List<OrderTicket> tickets;
  final OrderCheckout? checkout;
  factory OrderDetails.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailsFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderCheckout {
  const OrderCheckout(this.id, this.status, this.checkoutLinks);
  final String id;
  final String status;
  final List<OrderCheckoutLink> checkoutLinks;
  factory OrderCheckout.fromJson(Map<String, dynamic> json) =>
      _$OrderCheckoutFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderCheckoutLink {
  const OrderCheckoutLink(this.rel, this.href, this.method);
  final String rel;
  final String href;
  final String method;
  factory OrderCheckoutLink.fromJson(Map<String, dynamic> json) =>
      _$OrderCheckoutLinkFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderTicket {
  const OrderTicket(this.id, this.status, this.ticketType);
  final String id;
  final String status;
  final OrderTicketType ticketType;
  factory OrderTicket.fromJson(Map<String, dynamic> json) =>
      _$OrderTicketFromJson(json);
}

@JsonSerializable(createToJson: false)
class OrderTicketType {
  const OrderTicketType(this.name, this.price);
  final String name;
  @JsonKey(fromJson: _readAmount)
  final double price;
  factory OrderTicketType.fromJson(Map<String, dynamic> json) =>
      _$OrderTicketTypeFromJson(json);
}

@JsonSerializable(createToJson: false)
class RatingsPage {
  const RatingsPage(this.data, this.meta);
  final List<BuyerRating> data;
  final ActivityMeta meta;
  factory RatingsPage.fromJson(Map<String, dynamic> json) =>
      _$RatingsPageFromJson(json);
}

@JsonSerializable(createToJson: false)
class BuyerRating {
  const BuyerRating(
    this.eventId,
    this.eventTitle,
    this.userRating,
    this.averageRating,
    this.bannerUrl,
  );
  final String eventId;
  final String eventTitle;
  final int userRating;
  final double averageRating;
  final String? bannerUrl;
  factory BuyerRating.fromJson(Map<String, dynamic> json) =>
      _$BuyerRatingFromJson(json);
}

double _readAmount(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.parse(text),
  _ => throw FormatException('Valor inválido: $value'),
};
