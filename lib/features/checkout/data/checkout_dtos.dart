import 'package:json_annotation/json_annotation.dart';

part 'checkout_dtos.g.dart';

@JsonSerializable(createToJson: false)
class TicketTypePage {
  const TicketTypePage(this.data, this.meta);
  final List<CheckoutTicketType> data;
  final TicketTypeMeta meta;
  factory TicketTypePage.fromJson(Map<String, dynamic> json) =>
      _$TicketTypePageFromJson(json);
}

@JsonSerializable(createToJson: false)
class TicketTypeMeta {
  const TicketTypeMeta(this.currentPage, this.totalPages);
  final int currentPage;
  final int totalPages;
  factory TicketTypeMeta.fromJson(Map<String, dynamic> json) =>
      _$TicketTypeMetaFromJson(json);
}

@JsonSerializable(createToJson: false)
class CheckoutTicketType {
  const CheckoutTicketType({
    required this.id,
    required this.name,
    required this.price,
    required this.availableQuantity,
    required this.startDate,
    required this.endDate,
  });
  final String id;
  final String name;
  @JsonKey(fromJson: _readPrice)
  final double price;
  final int availableQuantity;
  final DateTime startDate;
  final DateTime endDate;
  factory CheckoutTicketType.fromJson(Map<String, dynamic> json) =>
      _$CheckoutTicketTypeFromJson(json);
}

@JsonSerializable(createToJson: false)
class CreatedOrderResponse {
  const CreatedOrderResponse(this.data);
  final CreatedOrder data;
  factory CreatedOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatedOrderResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class CreatedOrder {
  const CreatedOrder(this.orderId, this.checkoutLinks, this.ticketIds);
  final String orderId;
  final List<CheckoutPaymentLink> checkoutLinks;
  final List<String> ticketIds;
  factory CreatedOrder.fromJson(Map<String, dynamic> json) =>
      _$CreatedOrderFromJson(json);
}

@JsonSerializable(createToJson: false)
class CheckoutPaymentLink {
  const CheckoutPaymentLink(this.rel, this.href, this.method);
  final String rel;
  final String href;
  final String method;
  factory CheckoutPaymentLink.fromJson(Map<String, dynamic> json) =>
      _$CheckoutPaymentLinkFromJson(json);
}

@JsonSerializable(createToJson: false)
class AgeAcceptanceResponse {
  const AgeAcceptanceResponse(this.data);
  final AgeAcceptance data;
  factory AgeAcceptanceResponse.fromJson(Map<String, dynamic> json) =>
      _$AgeAcceptanceResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class AgeAcceptance {
  const AgeAcceptance(this.userHasAccepted);
  final bool userHasAccepted;
  factory AgeAcceptance.fromJson(Map<String, dynamic> json) =>
      _$AgeAcceptanceFromJson(json);
}

@JsonSerializable(createToJson: false)
class AgePolicyResponse {
  const AgePolicyResponse(this.data);
  final AgePolicy data;
  factory AgePolicyResponse.fromJson(Map<String, dynamic> json) =>
      _$AgePolicyResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class AgePolicy {
  const AgePolicy(this.id, this.description, this.version);
  final String id;
  final String description;
  final int version;
  factory AgePolicy.fromJson(Map<String, dynamic> json) =>
      _$AgePolicyFromJson(json);
}

double _readPrice(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.parse(text),
  _ => throw FormatException('Preço inválido: $value'),
};
