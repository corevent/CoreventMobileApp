import 'package:json_annotation/json_annotation.dart';

part 'ticket_dtos.g.dart';

@JsonSerializable(createToJson: false)
class TicketPage {
  const TicketPage({required this.data, required this.meta});
  final List<UserTicket> data;
  final TicketPageMeta meta;
  factory TicketPage.fromJson(Map<String, dynamic> json) =>
      _$TicketPageFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventTicketsResponse {
  const EventTicketsResponse({required this.data});
  final List<UserTicket> data;
  factory EventTicketsResponse.fromJson(Map<String, dynamic> json) =>
      _$EventTicketsResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class TicketPageMeta {
  const TicketPageMeta({required this.page, required this.totalPages});
  @JsonKey(name: 'currentPage')
  final int page;
  final int totalPages;
  factory TicketPageMeta.fromJson(Map<String, dynamic> json) =>
      _$TicketPageMetaFromJson(json);
}

@JsonSerializable(createToJson: false)
class UserTicket {
  const UserTicket({
    required this.id,
    required this.status,
    required this.ticketType,
    required this.event,
    required this.order,
    this.checkinAt,
    this.qrToken = '',
  });
  final String id;
  final String status;
  final DateTime? checkinAt;
  @JsonKey(defaultValue: '')
  final String qrToken;
  final UserTicketType ticketType;
  final UserTicketEvent event;
  final UserTicketOrder order;
  factory UserTicket.fromJson(Map<String, dynamic> json) =>
      _$UserTicketFromJson(json);
}

@JsonSerializable(createToJson: false)
class UserTicketType {
  const UserTicketType({
    required this.id,
    required this.name,
    required this.price,
  });
  final String id;
  final String name;
  final double price;
  factory UserTicketType.fromJson(Map<String, dynamic> json) =>
      _$UserTicketTypeFromJson(json);
}

@JsonSerializable(createToJson: false)
class UserTicketEvent {
  const UserTicketEvent({required this.id, required this.title});
  final String id;
  final String title;
  factory UserTicketEvent.fromJson(Map<String, dynamic> json) =>
      _$UserTicketEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class UserTicketOrder {
  const UserTicketOrder({required this.id, required this.status});
  final String id;
  final String status;
  factory UserTicketOrder.fromJson(Map<String, dynamic> json) =>
      _$UserTicketOrderFromJson(json);
}
