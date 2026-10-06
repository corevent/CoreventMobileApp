import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/data/event_dtos.dart';
import '../../events/data/events_repository.dart';
import '../../events/domain/event_catalog.dart';
import '../../events/domain/event_discovery_filter.dart';
import '../../events/presentation/event_preview_sheet.dart';
import '../../events/presentation/event_widgets.dart';
import '../../home/presentation/feed_components.dart';
import 'explore_view_model.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key, this.discovery});
  final EventDiscoveryFilter? discovery;

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final model = ref.read(exploreViewModelProvider.notifier);
      if (widget.discovery != null) {
        model.applyDiscovery(widget.discovery!);
      } else {
        model.load();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.discovery != null && widget.discovery != oldWidget.discovery) {
      searchController.clear();
      Future.microtask(() {
        if (mounted) {
          ref
              .read(exploreViewModelProvider.notifier)
              .applyDiscovery(widget.discovery!);
        }
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _clear() {
    searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    final router = GoRouter.maybeOf(context);
    if (router != null && widget.discovery?.isEmpty == false) {
      router.go('/explore?discover=all');
      return;
    }
    ref.read(exploreViewModelProvider.notifier).clearFilters();
  }

  void _open(EventSummary event) {
    FocusManager.instance.primaryFocus?.unfocus();
    showEventPreview(context, ref.read(eventsRepositoryProvider), event);
  }

  Future<void> _refresh() async {
    await ref.read(exploreViewModelProvider.notifier).refresh();
    if (!mounted) return;
    final error = ref.read(exploreViewModelProvider).refreshError;
    if (error != null) showErrorToast(context, error);
  }

  Widget _searchHeader(ExploreViewModel model, {required bool showClear}) =>
      DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: AppSurfaces.outline),
        ),
        child: pageBound(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: TextField(
              controller: searchController,
              onChanged: model.setSearch,
              onSubmitted: (_) => model.submitSearch(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Busque eventos, shows e experiências',
                prefixIcon: const Icon(
                  RemixIcons.search_line,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: !showClear
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          searchController.clear();
                          model.setSearch('');
                          model.submitSearch();
                        },
                        icon: const Icon(RemixIcons.close_line),
                      ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreViewModelProvider);
    final model = ref.read(exploreViewModelProvider.notifier);
    final filtering =
        state.search.trim().isNotEmpty ||
        state.category != null ||
        !state.discovery.isEmpty;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _searchHeader(model, showClear: state.search.isNotEmpty),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              elevation: 0,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: pageBound(
                      const FeedSectionTitle('Categorias'),
                      top: 28,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: pageBound(
                      _CategoryStrip(
                        selected: state.category,
                        onSelected: model.setCategory,
                      ),
                      top: 12,
                    ),
                  ),
                  if (state.loading)
                    SliverToBoxAdapter(
                      child: pageBound(const HomeSkeleton(), top: 24),
                    )
                  else if (state.error != null)
                    SliverToBoxAdapter(
                      child: pageBound(
                        FeedMessage(
                          icon: RemixIcons.wifi_off_line,
                          title: 'Eventos indisponíveis',
                          description: state.error!,
                          action: 'Tentar novamente',
                          onAction: model.load,
                        ),
                        top: 30,
                      ),
                    )
                  else if (state.events.isEmpty)
                    SliverToBoxAdapter(
                      child: pageBound(
                        FeedMessage(
                          icon: RemixIcons.calendar_close_line,
                          title: state.hasMore
                              ? 'Continue a descoberta'
                              : filtering
                              ? 'Nenhum evento encontrado'
                              : 'Ainda não há eventos',
                          description: state.hasMore
                              ? 'Carregue mais eventos para encontrar opções com esses critérios.'
                              : filtering
                              ? 'Tente outra busca ou categoria.'
                              : 'Volte em breve para descobrir novidades.',
                          action: state.hasMore
                              ? 'Carregar mais eventos'
                              : filtering
                              ? 'Limpar filtros'
                              : 'Atualizar',
                          onAction: state.hasMore
                              ? model.loadMore
                              : filtering
                              ? _clear
                              : model.refresh,
                        ),
                        top: 30,
                      ),
                    )
                  else ...[
                    if (state.discovery.locationType != null ||
                        state.discovery.from != null ||
                        state.discovery.until != null)
                      SliverToBoxAdapter(
                        child: pageBound(
                          Text(
                            [
                              if (state.discovery.locationType == 'online')
                                'Eventos online',
                              if (state.discovery.from != null)
                                'A partir de ${MaterialLocalizations.of(context).formatMediumDate(state.discovery.from!)}',
                              if (state.discovery.until != null)
                                'Até ${MaterialLocalizations.of(context).formatMediumDate(state.discovery.until!.subtract(const Duration(days: 1)))}',
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          top: 20,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: pageBound(
                        Row(
                          children: [
                            Expanded(
                              child: FeedSectionTitle(
                                filtering ? 'Resultados' : 'Todos os eventos',
                              ),
                            ),
                            if (filtering)
                              CoreventTextAction(
                                label: 'Limpar filtros',
                                onPressed: _clear,
                              ),
                          ],
                        ),
                        top: 24,
                      ),
                    ),
                    SliverList.builder(
                      itemCount: state.events.length,
                      itemBuilder: (context, index) {
                        final event = state.events[index];
                        return pageBound(
                          FeedReveal(
                            key: ValueKey(event.id),
                            child: EventSummaryCard(
                              event: event,
                              onTap: () => _open(event),
                            ),
                          ),
                          top: 12,
                        );
                      },
                    ),
                  ],
                  if (state.loadingMore)
                    SliverToBoxAdapter(
                      child: pageBound(
                        const FeedStatus(
                          'Carregando mais eventos…',
                          loading: true,
                        ),
                        top: 16,
                      ),
                    ),
                  if (state.loadMoreError != null)
                    SliverToBoxAdapter(
                      child: pageBound(
                        FeedStatus(
                          state.loadMoreError!,
                          onRetry: model.loadMore,
                        ),
                        top: 16,
                      ),
                    ),
                  if (state.hasMore &&
                      state.events.isNotEmpty &&
                      !state.loading &&
                      !state.loadingMore &&
                      state.loadMoreError == null)
                    SliverToBoxAdapter(
                      child: pageBound(
                        CoreventTextAction(
                          label: 'Carregar mais eventos',
                          onPressed: model.loadMore,
                        ),
                        top: 18,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _chip('Todos', selected == null, () => onSelected(null)),
        for (final category in EventCatalog.categories)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _chip(
              category.label,
              selected == category.value,
              () => onSelected(category.value),
            ),
          ),
      ],
    ),
  );

  Widget _chip(String label, bool isSelected, VoidCallback onTap) => ChoiceChip(
    label: Text(label),
    selected: isSelected,
    showCheckmark: false,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.orangeSoft,
    backgroundColor: AppColors.surface,
    side: BorderSide(
      color: isSelected ? AppColors.primary : AppColors.backgroundSecondary,
    ),
    labelStyle: TextStyle(
      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontFamily: 'PlusJakartaSans',
    ),
  );
}
