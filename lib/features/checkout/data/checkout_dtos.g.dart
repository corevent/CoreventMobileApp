// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketTypePage _$TicketTypePageFromJson(Map<String, dynamic> json) =>
    TicketTypePage(
      (json['data'] as List<dynamic>)
          .map((e) => CheckoutTicketType.fromJson(e as Map<String, dynamic>))
          .toList(),
      TicketTypeMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

TicketTypeMeta _$TicketTypeMetaFromJson(Map<String, dynamic> json) =>
    TicketTypeMeta(
      (json['currentPage'] as num).toInt(),
      (json['totalPages'] as num).toInt(),
    );

CheckoutTicketType _$CheckoutTicketTypeFromJson(Map<String, dynamic> json) =>
    CheckoutTicketType(
      id: json['id'] as String,
      name: json['name'] as String,
      price: _readPrice(json['price']),
      availableQuantity: (json['availableQuantity'] as num).toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );

CreatedOrderResponse _$CreatedOrderResponseFromJson(
  Map<String, dynamic> json,
) => CreatedOrderResponse(
  CreatedOrder.fromJson(json['data'] as Map<String, dynamic>),
);

CreatedOrder _$CreatedOrderFromJson(Map<String, dynamic> json) => CreatedOrder(
  json['orderId'] as String,
  (json['checkoutLinks'] as List<dynamic>)
      .map((e) => CheckoutPaymentLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  (json['ticketIds'] as List<dynamic>).map((e) => e as String).toList(),
);

CheckoutPaymentLink _$CheckoutPaymentLinkFromJson(Map<String, dynamic> json) =>
    CheckoutPaymentLink(
      json['rel'] as String,
      json['href'] as String,
      json['method'] as String,
    );

AgeAcceptanceResponse _$AgeAcceptanceResponseFromJson(
  Map<String, dynamic> json,
) => AgeAcceptanceResponse(
  AgeAcceptance.fromJson(json['data'] as Map<String, dynamic>),
);

AgeAcceptance _$AgeAcceptanceFromJson(Map<String, dynamic> json) =>
    AgeAcceptance(json['userHasAccepted'] as bool);

AgePolicyResponse _$AgePolicyResponseFromJson(Map<String, dynamic> json) =>
    AgePolicyResponse(AgePolicy.fromJson(json['data'] as Map<String, dynamic>));

AgePolicy _$AgePolicyFromJson(Map<String, dynamic> json) => AgePolicy(
  json['id'] as String,
  json['description'] as String,
  (json['version'] as num).toInt(),
);
