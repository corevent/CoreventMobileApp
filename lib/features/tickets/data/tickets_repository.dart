import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'ticket_dtos.dart';
import 'tickets_api.dart';

class TicketsRepository {
  const TicketsRepository(this.api);
  final TicketsApi api;

  Future<TicketPage> list({required int page}) => api.mine(page, 20);

  Future<UserTicket?> refreshTicket(UserTicket ticket) async {
    final response = await api.mineForEvent(ticket.event.id);
    for (final item in response.data) {
      if (item.id == ticket.id) return item;
    }
    return null;
  }
}

final ticketsApiProvider = Provider<TicketsApi>(
  (ref) => TicketsApi(ref.watch(authorizedDioProvider)),
);

final ticketsRepositoryProvider = Provider<TicketsRepository>(
  (ref) => TicketsRepository(ref.watch(ticketsApiProvider)),
);
