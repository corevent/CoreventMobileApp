import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/theme/app_colors.dart';
import '../../events/data/event_dtos.dart';
import '../../events/data/events_repository.dart';
import '../../events/presentation/event_widgets.dart';
import '../data/ticket_dtos.dart';
import 'ticket_status.dart';

Future<void> showTicketDetail(
  BuildContext context,
  UserTicket ticket,
  EventsRepository eventsRepository, {
  required VoidCallback onShowQr,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => _TicketDetailSheet(
    ticket: ticket,
    eventsRepository: eventsRepository,
    onShowQr: onShowQr,
  ),
);

class _TicketDetailSheet extends StatefulWidget {
  const _TicketDetailSheet({
    required this.ticket,
    required this.eventsRepository,
    required this.onShowQr,
  });

  final UserTicket ticket;
  final EventsRepository eventsRepository;
  final VoidCallback onShowQr;

  @override
  State<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<_TicketDetailSheet> {
  late Future<EventDetail> eventFuture;

  @override
  void initState() {
    super.initState();
    eventFuture = widget.eventsRepository.detail(widget.ticket.event.id);
  }

  void _retry() => setState(() {
    eventFuture = widget.eventsRepository.detail(widget.ticket.event.id);
  });

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final status = ticketVisualStatus(ticket);
    final price = NumberFormat.simpleCurrency(locale: 'pt_BR')
        .format(ticket.ticketType.price);

    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar detalhes do ingresso',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(RemixIcons.close_line),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (canShowTicketQr(ticket)) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onShowQr();
                    },
                    icon: const Icon(RemixIcons.qr_code_line),
                    label: const Text('Ver QR Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _DetailRow(
                icon: RemixIcons.ticket_line,
                label: 'Tipo de ingresso',
                value: ticket.ticketType.name,
              ),
              const SizedBox(height: 16),
              FutureBuilder<EventDetail>(
                future: eventFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final event = snapshot.data!;
                    return Column(
                      children: [
                        _DetailRow(
                          icon: RemixIcons.calendar_event_line,
                          label: 'Data e horário',
                          value: eventDate(context, event.startDate),
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: RemixIcons.map_pin_line,
                          label: 'Local',
                          value: eventLocation(
                            event.locationName,
                            event.locationType,
                          ),
                        ),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Data e local indisponíveis.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: _retry,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    );
                  }
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
              if (ticket.checkinAt != null) ...[
                const SizedBox(height: 16),
                _DetailRow(
                  icon: RemixIcons.checkbox_circle_line,
                  label: 'Entrada registrada em',
                  value: eventDate(context, ticket.checkinAt!),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(color: AppColors.backgroundSecondary),
              const SizedBox(height: 16),
              _DetailRow(
                icon: RemixIcons.price_tag_3_line,
                label: 'Preço do tipo de ingresso',
                value: price,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: RemixIcons.hashtag,
                label: 'Identificador do ingresso',
                value: ticket.id,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: RemixIcons.receipt_line,
                label: 'Identificador do pedido',
                value: ticket.order.id,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppColors.primaryDark),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
