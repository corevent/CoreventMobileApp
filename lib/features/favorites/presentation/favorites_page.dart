import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_dialog_styles.dart';
import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/data/event_dtos.dart';
import '../../events/data/events_repository.dart';
import '../../events/presentation/event_preview_sheet.dart';
import '../../events/presentation/event_widgets.dart';
import '../../home/presentation/feed_components.dart';
import '../../profile/presentation/profile_form_pages.dart';
import 'event_favorites_view_model.dart';
import 'favorites_view_model.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});
  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController fade;
  final scroll = ScrollController();
  bool switching = false;

  @override
  void initState() {
    super.initState();
    fade = AnimationController(
      vsync: this,
      value: 1,
      duration: AppMotion.quick,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(favoritesViewModelProvider).hasLoaded) {
        ref.read(favoritesViewModelProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    fade.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _select(FavoriteStatus status) async {
    if (switching || status == ref.read(favoritesViewModelProvider).status) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => switching = true);
    fade.duration = AppMotion.duration(context, AppMotion.quick);
    await fade.reverse();
    if (!mounted) return;
    ref.read(favoritesViewModelProvider.notifier).selectStatus(status);
    if (scroll.hasClients) scroll.jumpTo(0);
    await fade.forward();
    if (mounted) setState(() => switching = false);
  }

  Future<void> _refresh() async {
    final error = await ref.read(favoritesViewModelProvider.notifier).refresh();
    if (mounted && error != null) showErrorToast(context, error);
  }

  void _open(EventSummary event) =>
      showEventPreview(context, ref.read(eventsRepositoryProvider), event);

  Future<void> _remove(EventSummary event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        elevation: 0,
        backgroundColor: AppColors.surface,
        titleTextStyle: AppDialogStyles.title,
        title: const Text('Remover favorito?'),
        content: Text('Remover “${event.title}” dos seus favoritos?'),
        actions: [
          TextButton(
            style: AppDialogStyles.action,
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: AppDialogStyles.destructiveAction,
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final removed = await ref
        .read(favoritesViewModelProvider.notifier)
        .remove(event);
    if (removed && mounted) {
      ref
          .read(eventFavoritesViewModelProvider.notifier)
          .recordRemoval(event.id);
    }
    if (!removed && mounted) {
      showErrorToast(
        context,
        'Não foi possível remover o favorito. Tente novamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesViewModelProvider);
    final model = ref.read(favoritesViewModelProvider.notifier);
    return ProfileSubpage(
      title: 'Favoritos',
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: AppSurfaces.outline),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                children: [
                  for (final status in FavoriteStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status.label),
                        selected: status == state.status,
                        showCheckmark: false,
                        selectedColor: AppColors.orangeSoft,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: status == state.status
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: status == state.status
                              ? AppColors.primary.withAlpha(70)
                              : AppColors.backgroundSecondary,
                        ),
                        onSelected: (_) => _select(status),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              elevation: 0,
              onRefresh: _refresh,
              child: FadeTransition(
                opacity: fade,
                child: AbsorbPointer(
                  absorbing: switching,
                  child: CustomScrollView(
                    controller: scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (state.loading ||
                          (!state.hasLoaded && state.error == null))
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: _FavoritesSkeleton(),
                          ),
                        )
                      else if (state.error != null)
                        SliverToBoxAdapter(
                          child: pageBound(
                            FeedMessage(
                              icon: RemixIcons.wifi_off_line,
                              title: 'Favoritos indisponíveis',
                              description: state.error!,
                              action: 'Tentar novamente',
                              onAction: model.load,
                            ),
                            top: 20,
                          ),
                        )
                      else ...[
                        _FavoriteList(
                          key: ValueKey(state.status),
                          events: state.events,
                          removingIds: state.removingIds,
                          onOpen: _open,
                          onRemove: _remove,
                        ),
                        if (state.events.isEmpty && !state.hasMore)
                          SliverToBoxAdapter(
                            child: pageBound(
                              FeedMessage(
                                icon: RemixIcons.heart_line,
                                title: state.status.emptyTitle,
                                description: 'Explore eventos e salve os que você quer acompanhar.',
                                action: 'Explorar eventos',
                                onAction: () => context.go('/explore'),
                              ),
                              top: 20,
                            ),
                          ),
                        if (state.hasMore || state.loadMoreError != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (state.loadMoreError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        state.loadMoreError!,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  TextButton.icon(
                                    onPressed:
                                        state.loadingMore || state.refreshing
                                        ? null
                                        : model.loadMore,
                                    icon: state.loadingMore
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : const Icon(
                                            RemixIcons.arrow_down_s_line,
                                          ),
                                    label: Text(
                                      state.loadingMore
                                          ? 'Carregando…'
                                          : state.loadMoreError != null
                                          ? 'Tentar novamente'
                                          : 'Carregar mais',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteList extends StatefulWidget {
  const _FavoriteList({
    super.key,
    required this.events,
    required this.removingIds,
    required this.onOpen,
    required this.onRemove,
  });
  final List<EventSummary> events;
  final Set<String> removingIds;
  final ValueChanged<EventSummary> onOpen;
  final ValueChanged<EventSummary> onRemove;
  @override
  State<_FavoriteList> createState() => _FavoriteListState();
}

class _FavoriteListState extends State<_FavoriteList> {
  final listKey = GlobalKey<SliverAnimatedListState>();
  late final List<EventSummary> items = [...widget.events];

  @override
  void didUpdateWidget(covariant _FavoriteList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final duration = AppMotion.duration(context, AppMotion.standard);
    for (var i = items.length - 1; i >= 0; i--) {
      if (!widget.events.any((e) => e.id == items[i].id)) {
        final removed = items.removeAt(i);
        listKey.currentState?.removeItem(
          i,
          (context, animation) => ExcludeSemantics(
            child: IgnorePointer(child: _animated(removed, animation)),
          ),
          duration: duration,
        );
      }
    }
    for (var i = 0; i < widget.events.length; i++) {
      final event = widget.events[i];
      final index = items.indexWhere((e) => e.id == event.id);
      if (index == i) {
        items[i] = event;
      } else {
        if (index >= 0) {
          final moved = items.removeAt(index);
          listKey.currentState?.removeItem(
            index,
            (_, animation) => ExcludeSemantics(
              child: IgnorePointer(child: _animated(moved, animation)),
            ),
            duration: Duration.zero,
          );
        }
        items.insert(i, event);
        listKey.currentState?.insertItem(i, duration: duration);
      }
    }
  }

  Widget _animated(EventSummary event, Animation<double> animation) =>
      SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: EventSummaryCard(
              event: event,
              onTap: () => widget.onOpen(event),
              action: IconButton(
                tooltip: widget.removingIds.contains(event.favoriteId)
                    ? 'Removendo ${event.title}'
                    : 'Remover ${event.title} dos favoritos',
                onPressed:
                    event.favoriteId == null ||
                        widget.removingIds.contains(event.favoriteId)
                    ? null
                    : () => widget.onRemove(event),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: widget.removingIds.contains(event.favoriteId)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pink,
                        ),
                      )
                    : const Icon(RemixIcons.heart_fill, color: AppColors.pink),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => SliverAnimatedList(
    key: listKey,
    initialItemCount: items.length,
    itemBuilder: (_, index, animation) => _animated(items[index], animation),
  );
}

class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: AppSurfaces.cardDecoration,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _block(102, 110),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _block(68, 20),
                        const SizedBox(height: 12),
                        _block(double.infinity, 18),
                        const SizedBox(height: 8),
                        _block(double.infinity, 14),
                        const SizedBox(height: 8),
                        _block(90, 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  Widget _block(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
