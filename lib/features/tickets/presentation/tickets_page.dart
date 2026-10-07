import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/data/events_repository.dart';
import '../../home/presentation/feed_components.dart';
import '../data/ticket_dtos.dart';
import '../data/tickets_repository.dart';
import 'ticket_detail_sheet.dart';
import 'ticket_qr_page.dart';
import 'ticket_status.dart';
import 'tickets_view_model.dart';

class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({super.key});

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(ticketsViewModelProvider.notifier).load();
    });
  }

  Future<void> _refresh() async {
    await ref.read(ticketsViewModelProvider.notifier).refresh();
    if (!mounted) return;
    final error = ref.read(ticketsViewModelProvider).refreshError;
    if (error != null) showErrorToast(context, error);
  }

  Future<void> _showQr(UserTicket ticket) async {
    await showTicketQr(context, ticket, ref.read(ticketsRepositoryProvider));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketsViewModelProvider);
    final model = ref.read(ticketsViewModelProvider.notifier);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        elevation: 0,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (state.loading)
              SliverToBoxAdapter(
                child: pageBound(
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  top: 28,
                ),
              )
            else if (state.error != null)
              SliverToBoxAdapter(
                child: pageBound(
                  FeedMessage(
                    icon: RemixIcons.wifi_off_line,
                    title: 'Ingressos indisponíveis',
                    description: state.error!,
                    action: 'Tentar novamente',
                    onAction: model.load,
                  ),
                  top: 26,
                ),
              )
            else if (state.items.isEmpty)
              SliverToBoxAdapter(
                child: pageBound(
                  FeedMessage(
                    icon: RemixIcons.ticket_line,
                    title: 'Nenhum ingresso ainda',
                    description:
                        'Quando você adquirir um ingresso, ele aparecerá aqui.',
                    action: 'Atualizar',
                    onAction: model.refresh,
                  ),
                  top: 26,
                ),
              )
            else
              SliverList.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) => pageBound(
                  _TicketCard(
                    ticket: state.items[index],
                    onQrTap: canShowTicketQr(state.items[index])
                        ? () => _showQr(state.items[index])
                        : null,
                    onTap: () => showTicketDetail(
                      context,
                      state.items[index],
                      ref.read(eventsRepositoryProvider),
                      onShowQr: () => _showQr(state.items[index]),
                    ),
                  ),
                  top: index == 0 ? 20 : 12,
                ),
              ),
            if (state.loadingMore)
              SliverToBoxAdapter(
                child: pageBound(
                  const FeedStatus('Carregando mais ingressos…', loading: true),
                  top: 16,
                ),
              ),
            if (state.loadMoreError != null)
              SliverToBoxAdapter(
                child: pageBound(
                  FeedStatus(state.loadMoreError!, onRetry: model.loadMore),
                  top: 16,
                ),
              ),
            if (state.hasMore &&
                !state.loading &&
                !state.loadingMore &&
                state.loadMoreError == null)
              SliverToBoxAdapter(
                child: pageBound(
                  CoreventTextAction(
                    label: 'Carregar mais ingressos',
                    onPressed: model.loadMore,
                  ),
                  top: 16,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.onTap,
    required this.onQrTap,
  });
  final UserTicket ticket;
  final VoidCallback onTap;
  final VoidCallback? onQrTap;

  @override
  Widget build(BuildContext context) {
    final visualStatus = ticketVisualStatus(ticket);
    return Semantics(
      button: true,
      label: 'Ver detalhes do ingresso para ${ticket.event.title}',
      child: Material(
        color: AppColors.surface,
        shape: AppSurfaces.cardShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        RemixIcons.ticket_line,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.event.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.ticketType.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TicketBadge(
                      label: visualStatus.label,
                      color: visualStatus.color,
                      background: visualStatus.background,
                    ),
                    if (ticket.checkinAt != null)
                      const _TicketBadge(
                        label: 'Entrada registrada',
                        color: AppColors.textSecondary,
                        background: AppColors.backgroundSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.backgroundSecondary),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ingresso ${_shortId(ticket.id)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      RemixIcons.arrow_right_s_line,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (onQrTap != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onQrTap,
                      icon: const Icon(RemixIcons.qr_code_line),
                      label: const Text('Ver QR Code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _shortId(String id) => id.length <= 8
    ? id.toUpperCase()
    : id.substring(id.length - 8).toUpperCase();

class _TicketBadge extends StatelessWidget {
  const _TicketBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
