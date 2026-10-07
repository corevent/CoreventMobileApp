// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketPage _$TicketPageFromJson(Map<String, dynamic> json) => TicketPage(
  data: (json['data'] as List<dynamic>)
      .map((e) => UserTicket.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: TicketPageMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

EventTicketsResponse _$EventTicketsResponseFromJson(
  Map<String, dynamic> json,
) => EventTicketsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => UserTicket.fromJson(e as Map<String, dynamic>))
      .toList(),
);

TicketPageMeta _$TicketPageMetaFromJson(Map<String, dynamic> json) =>
    TicketPageMeta(
      page: (json['currentPage'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

UserTicket _$UserTicketFromJson(Map<String, dynamic> json) => UserTicket(
  id: json['id'] as String,
  status: json['status'] as String,
  ticketType: UserTicketType.fromJson(
    json['ticketType'] as Map<String, dynamic>,
  ),
  event: UserTicketEvent.fromJson(json['event'] as Map<String, dynamic>),
  order: UserTicketOrder.fromJson(json['order'] as Map<String, dynamic>),
  checkinAt: json['checkinAt'] == null
      ? null
      : DateTime.parse(json['checkinAt'] as String),
  qrToken: json['qrToken'] as String? ?? '',
);

UserTicketType _$UserTicketTypeFromJson(Map<String, dynamic> json) =>
    UserTicketType(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );

UserTicketEvent _$UserTicketEventFromJson(Map<String, dynamic> json) =>
    UserTicketEvent(id: json['id'] as String, title: json['title'] as String);

UserTicketOrder _$UserTicketOrderFromJson(Map<String, dynamic> json) =>
    UserTicketOrder(id: json['id'] as String, status: json['status'] as String);
