import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../data/activity_dtos.dart';
import '../data/activity_repository.dart';
import 'activity_view_model.dart';
import 'profile_form_pages.dart';

final _date = DateFormat('dd MMM yyyy', 'pt_BR');
final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key, required this.kind});
  final ActivityKind kind;
  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  NotifierProvider<ActivityViewModel, ActivityState> get provider =>
      switch (widget.kind) {
        ActivityKind.orders => ordersViewModelProvider,
        ActivityKind.ratings => ratingsViewModelProvider,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(provider.notifier).load();
    });
  }

  Future<void> _refresh() async {
    await ref.read(provider.notifier).load();
    if (!mounted) return;
    final error = ref.read(provider).error;
    if (error != null) showErrorToast(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provider);
    final model = ref.read(provider.notifier);
    final title = switch (widget.kind) {
      ActivityKind.orders => 'Pedidos',
      ActivityKind.ratings => 'Avaliações',
    };
    return ProfileSubpage(
      title: title,
      child: RefreshIndicator(
        color: AppColors.primary,
        elevation: 0,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (state.loading && state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state.error != null && state.items.isEmpty)
              _Notice(
                state.error!,
                action: 'Tentar novamente',
                onTap: model.load,
              )
            else if (state.items.isEmpty)
              _Notice(switch (widget.kind) {
                ActivityKind.orders => 'Você ainda não fez pedidos.',
                ActivityKind.ratings => 'Você ainda não avaliou eventos.',
              })
            else ...[
              for (final item in state.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: switch (item) {
                    final BuyerOrder order => _ActivityTile(
                      icon: RemixIcons.receipt_line,
                      title: order.event.title,
                      subtitle:
                          '${_date.format(order.createdAt.toLocal())}  •  ${_money.format(order.totalAmount)}',
                      trailing: _orderStatus(order.status),
                      onTap: () => context.push('/profile/orders/${order.id}'),
                    ),
                    final BuyerRating rating => _ActivityTile(
                      icon: RemixIcons.star_line,
                      title: rating.eventTitle,
                      subtitle: '${rating.userRating} de 5 estrelas',
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              if (state.error != null)
                _Notice(
                  state.error!,
                  action: 'Tentar novamente',
                  onTap: model.loadMore,
                ),
              if (state.hasMore)
                Center(
                  child: TextButton(
                    onPressed: state.loadingMore ? null : model.loadMore,
                    child: Text(
                      state.loadingMore ? 'Carregando…' : 'Carregar mais',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: AppSurfaces.cardShape,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      trailing: onTap == null
          ? null
          : const Icon(RemixIcons.arrow_right_s_line),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.message, {this.action, this.onTap});
  final String message;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (action != null)
            TextButton(onPressed: onTap, child: Text(action!)),
        ],
      ),
    ),
  );
}

String _orderStatus(String status) => switch (status.toLowerCase()) {
  'paid' || 'completed' => 'Pago',
  'pending' => 'Aguardando pagamento',
  'canceled' || 'cancelled' => 'Cancelado',
  _ => status,
};

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  late Future<OrderDetails> detail;

  @override
  void initState() {
    super.initState();
    detail = ref.read(activityRepositoryProvider).order(widget.id);
  }

  void retry() => setState(() {
    detail = ref.read(activityRepositoryProvider).order(widget.id);
  });

  @override
  Widget build(BuildContext context) => ProfileSubpage(
    title: 'Detalhes do pedido',
    child: FutureBuilder<OrderDetails>(
      future: detail,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Não foi possível carregar o pedido.'),
                      TextButton(
                        onPressed: retry,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final order = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              order.event.title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Text('Status: ${_orderStatus(order.status)}'),
            Text('Pedido feito em ${_date.format(order.createdAt.toLocal())}'),
            Text('Total: ${_money.format(order.totalAmount)}'),
            if (order.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.push('/orders/${order.id}/status'),
                child: const Text('Acompanhar pagamento'),
              ),
            ],
            const SizedBox(height: 26),
            Text(
              'Itens',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            for (final ticket in order.tickets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ticket.ticketType.name),
                subtitle: Text(ticket.status),
                trailing: Text(_money.format(ticket.ticketType.price)),
              ),
          ],
        );
      },
    ),
  );
}
