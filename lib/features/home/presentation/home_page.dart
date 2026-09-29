import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_session.dart';
import '../../events/data/event_dtos.dart';
import '../../events/data/events_repository.dart';
import '../../events/domain/event_discovery_filter.dart';
import '../../events/domain/event_visibility.dart';
import '../../events/presentation/event_preview_sheet.dart';
import '../../events/presentation/event_widgets.dart';
import '../../favorites/presentation/event_favorites_view_model.dart';
import '../domain/home_feed.dart';
import 'feed_components.dart';
import 'home_discovery_components.dart';
import 'home_view_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  DateTime now = DateTime.now();
  Timer? greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleGreeting();
    Future.microtask(() {
      if (!mounted) return;
      if (ref.read(homeViewModelProvider).page == 0) {
        unawaited(ref.read(homeViewModelProvider.notifier).load());
      }
      unawaited(ref.read(eventFavoritesViewModelProvider.notifier).load());
    });
  }

  void _scheduleGreeting() {
    greetingTimer?.cancel();
    final current = DateTime.now();
    final hour = current.hour < 5
        ? 5
        : current.hour < 12
        ? 12
        : current.hour < 18
        ? 18
        : 24;
    final next = DateTime(current.year, current.month, current.day, hour);
    greetingTimer = Timer(next.difference(current), () {
      if (mounted) setState(() => now = DateTime.now());
      _scheduleGreeting();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => now = DateTime.now());
      _scheduleGreeting();
    }
  }

  @override
  void dispose() {
    greetingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _open(EventSummary event) =>
      showEventPreview(context, ref.read(eventsRepositoryProvider), event);

  void _explore([EventDiscoveryFilter filter = const EventDiscoveryFilter()]) {
    context.go(
      Uri(
        path: '/explore',
        queryParameters: {'discover': 'all', ...filter.query},
      ).toString(),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(homeViewModelProvider.notifier).refresh(),
      ref.read(eventFavoritesViewModelProvider.notifier).load(refresh: true),
    ]);
    if (!mounted) return;
    setState(() => now = DateTime.now());
    final errors = [
      ref.read(homeViewModelProvider).refreshError,
      ref.read(eventFavoritesViewModelProvider).error,
    ].whereType<String>().toList();
    if (errors.isNotEmpty) showErrorToast(context, errors.join(' '));
  }

  Widget _block(Widget child, {double top = 0}) =>
      SliverToBoxAdapter(child: pageBound(child, top: top));

  Widget _link({required String label, required VoidCallback onPressed}) =>
      Align(
        alignment: Alignment.centerLeft,
        child: CoreventTextAction(label: label, onPressed: onPressed),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final session = ref.watch(authSessionProvider);
    final favorites = ref.watch(eventFavoritesViewModelProvider);
    final saved = visibleEvents(
      {
        ...favorites.events,
        for (final e in state.events) e.id: e,
      }.values.where((e) => favorites.ids.containsKey(e.id)),
      birthDate: session.user?.birthDate,
      now: now,
    );
    final feed = HomeSections.from(state.events, now, saved: saved);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          ListenableBuilder(
            listenable: session,
            builder: (context, _) {
              final name = session.user?.name.trim() ?? '';
              final firstName = name.isEmpty
                  ? ''
                  : name.split(RegExp(r'\s+')).first;
              return _GreetingHeader(
                firstName: firstName,
                hour: now.hour,
                avatarUrl: session.user?.avatarUrl,
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              elevation: 0,
              onRefresh: _refresh,
              child: CustomScrollView(
                key: const PageStorageKey('home-discovery'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.loading)
                    _block(const HomeSkeleton(), top: 24)
                  else if (state.error != null)
                    _block(
                      FeedMessage(
                        icon: RemixIcons.wifi_off_line,
                        title: 'Eventos indisponíveis',
                        description: state.error!,
                        action: 'Tentar novamente',
                        onAction: viewModel.load,
                      ),
                      top: 24,
                    )
                  else if (feed.featured == null)
                    _block(
                      FeedMessage(
                        icon: RemixIcons.calendar_close_line,
                        title: 'Ainda não há eventos',
                        description: 'Volte em breve para descobrir novidades.',
                        action: 'Atualizar',
                        onAction: _refresh,
                      ),
                      top: 24,
                    )
                  else ...[
                    _block(
                      FeedSectionTitle(
                        feed.featured!.startDate.toLocal().isBefore(now)
                            ? 'Acontecendo agora'
                            : 'Para sua próxima saída',
                      ),
                      top: 24,
                    ),
                    _block(
                      FeedReveal(
                        key: ValueKey('featured-${feed.featured!.id}'),
                        child: EventSummaryCard(
                          event: feed.featured!,
                          featured: true,
                          onTap: () => _open(feed.featured!),
                        ),
                      ),
                      top: 14,
                    ),
                  ],
                  _block(
                    const FeedSectionTitle('Encontre sua experiência'),
                    top: 28,
                  ),
                  _block(
                    HomeInterestGrid(
                      onSelected: (category) =>
                          _explore(EventDiscoveryFilter(category: category)),
                    ),
                    top: 14,
                  ),
                  _block(
                    _link(
                      label: 'Ver todas as categorias',
                      onPressed: () => _explore(),
                    ),
                    top: 4,
                  ),
                  if (!state.loading && state.error == null)
                    for (final section in feed.sections) ...[
                      _block(FeedSectionTitle(section.title), top: 28),
                      _block(
                        HomeEventCollection(
                          events: section.events,
                          onOpen: _open,
                        ),
                        top: 14,
                      ),
                      if (section.id != 'more')
                        _block(
                          _link(
                            label: section.actionLabel,
                            onPressed: () {
                              if (section.favorites) {
                                context.push('/profile/favorites');
                              } else {
                                _explore(section.filter);
                              }
                            },
                          ),
                          top: 4,
                        ),
                    ],
                  if (favorites.error != null && !favorites.loaded)
                    _block(
                      _SourceFailure(
                        label: 'Não foi possível consultar seus favoritos.',
                        onRetry: () => ref
                            .read(eventFavoritesViewModelProvider.notifier)
                            .load(refresh: true),
                      ),
                      top: 20,
                    ),
                  _block(
                    _link(
                      label: 'Continuar em Explorar',
                      onPressed: () => _explore(),
                    ),
                    top: 20,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceFailure extends StatelessWidget {
  const _SourceFailure({required this.label, required this.onRetry});
  final String label;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      CoreventTextAction(label: 'Tentar novamente', onPressed: onRetry),
    ],
  );
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.firstName,
    required this.hour,
    this.avatarUrl,
  });
  final String firstName;
  final int hour;
  final String? avatarUrl;
  @override
  Widget build(BuildContext context) {
    final greeting = hour >= 5 && hour < 12
        ? 'Bom dia'
        : hour >= 12 && hour < 18
        ? 'Boa tarde'
        : 'Boa noite';
    final initial = firstName.isEmpty
        ? 'C'
        : firstName.characters.first.toUpperCase();
    final avatar = avatarUrl?.trim();
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: AppSurfaces.outline),
      ),
      child: pageBound(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName.isEmpty
                          ? 'Descubra eventos'
                          : 'Olá, $firstName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Abrir perfil',
                onPressed: () => context.go('/profile'),
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.orangeSoft,
                  foregroundImage: hasAvatar ? NetworkImage(avatar) : null,
                  onForegroundImageError: hasAvatar ? (_, _) {} : null,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
