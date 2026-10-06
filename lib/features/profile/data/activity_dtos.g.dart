// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityMeta _$ActivityMetaFromJson(Map<String, dynamic> json) => ActivityMeta(
  (json['currentPage'] as num).toInt(),
  (json['totalPages'] as num).toInt(),
);

OrderPage _$OrderPageFromJson(Map<String, dynamic> json) => OrderPage(
  (json['data'] as List<dynamic>)
      .map((e) => BuyerOrder.fromJson(e as Map<String, dynamic>))
      .toList(),
  ActivityMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

BuyerOrder _$BuyerOrderFromJson(Map<String, dynamic> json) => BuyerOrder(
  json['id'] as String,
  OrderEvent.fromJson(json['event'] as Map<String, dynamic>),
  _readAmount(json['totalAmount']),
  json['status'] as String,
  DateTime.parse(json['createdAt'] as String),
);

OrderEvent _$OrderEventFromJson(Map<String, dynamic> json) => OrderEvent(
  json['id'] as String,
  json['title'] as String,
  DateTime.parse(json['startDate'] as String),
);

OrderDetailsResponse _$OrderDetailsResponseFromJson(
  Map<String, dynamic> json,
) => OrderDetailsResponse(
  OrderDetails.fromJson(json['data'] as Map<String, dynamic>),
);

OrderDetails _$OrderDetailsFromJson(Map<String, dynamic> json) => OrderDetails(
  json['id'] as String,
  OrderEvent.fromJson(json['event'] as Map<String, dynamic>),
  _readAmount(json['totalAmount']),
  json['status'] as String,
  DateTime.parse(json['createdAt'] as String),
  (json['tickets'] as List<dynamic>)
      .map((e) => OrderTicket.fromJson(e as Map<String, dynamic>))
      .toList(),
  json['checkout'] == null
      ? null
      : OrderCheckout.fromJson(json['checkout'] as Map<String, dynamic>),
);

OrderCheckout _$OrderCheckoutFromJson(Map<String, dynamic> json) =>
    OrderCheckout(
      json['id'] as String,
      json['status'] as String,
      (json['checkoutLinks'] as List<dynamic>)
          .map((e) => OrderCheckoutLink.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

OrderCheckoutLink _$OrderCheckoutLinkFromJson(Map<String, dynamic> json) =>
    OrderCheckoutLink(
      json['rel'] as String,
      json['href'] as String,
      json['method'] as String,
    );

OrderTicket _$OrderTicketFromJson(Map<String, dynamic> json) => OrderTicket(
  json['id'] as String,
  json['status'] as String,
  OrderTicketType.fromJson(json['ticketType'] as Map<String, dynamic>),
);

OrderTicketType _$OrderTicketTypeFromJson(Map<String, dynamic> json) =>
    OrderTicketType(json['name'] as String, _readAmount(json['price']));

RatingsPage _$RatingsPageFromJson(Map<String, dynamic> json) => RatingsPage(
  (json['data'] as List<dynamic>)
      .map((e) => BuyerRating.fromJson(e as Map<String, dynamic>))
      .toList(),
  ActivityMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

BuyerRating _$BuyerRatingFromJson(Map<String, dynamic> json) => BuyerRating(
  json['eventId'] as String,
  json['eventTitle'] as String,
  (json['userRating'] as num).toInt(),
  (json['averageRating'] as num).toDouble(),
  json['bannerUrl'] as String?,
);
