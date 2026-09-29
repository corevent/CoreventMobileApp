import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/events/domain/event_discovery_filter.dart';
import 'package:corevent_mobile_app/features/explore/presentation/explore_page.dart';
import 'package:corevent_mobile_app/features/explore/presentation/explore_view_model.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/home/presentation/home_discovery_components.dart';
import 'package:corevent_mobile_app/features/home/presentation/home_page.dart';
import 'package:corevent_mobile_app/features/tickets/data/ticket_dtos.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockEvents extends Mock implements EventsRepository {}

class MockFavorites extends Mock implements FavoritesRepository {}

class MockTickets extends Mock implements TicketsRepository {}

class MockSession extends Mock implements AuthSession {}

void main() {
  late MockEvents events;
  late MockFavorites favorites;
  late MockTickets tickets;
  late MockSession session;
  late List<EventSummary> catalog;
  late GoRouter router;
  late ProviderContainer container;

  setUpAll(() async {
    await (FontLoader('PlusJakartaSans')..addFont(
          rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont_wght.ttf'),
        ))
        .load();
    await (FontLoader(
      'packages/remixicon/remix',
    )..addFont(rootBundle.load('packages/remixicon/fonts/remix.ttf'))).load();
  });

  setUp(() {
    events = MockEvents();
    favorites = MockFavorites();
    tickets = MockTickets();
    session = MockSession();
    final now = DateTime.now();
    EventSummary event(
      String id,
      DateTime date, {
      String category = 'music',
      String? mode,
      String? favoriteId,
    }) => EventSummary(
      id: id,
      title: 'Evento $id',
      startDate: date,
      endDate: date.add(const Duration(hours: 3)),
      category: category,
      locationType: mode,
      favoriteId: favoriteId,
      isAdultOnly: false,
      locationName: 'Praça Central',
      cityName: 'Jaú',
      stateAcronym: 'SP',
      averageRating: 4.8,
      organizer: const EventOrganizer(name: 'Corevent'),
    );
    final weekend = EventDiscoveryFilter.weekend(now);
    final weekendDate = weekend.from!.isAfter(now)
        ? weekend.from!.add(const Duration(days: 1, hours: 12))
        : now.add(const Duration(hours: 2));
    catalog = [
      event('destaque', now.add(const Duration(minutes: 30))),
      event('fim-de-semana', weekendDate),
      event(
        'salvo',
        now.add(const Duration(days: 12)),
        category: 'gastronomy',
        favoriteId: 'fav-1',
      ),
      event('musica', now.add(const Duration(days: 20))),
      event('arte', now.add(const Duration(days: 21)), category: 'art_culture'),
      event(
        'online',
        now.add(const Duration(days: 22)),
        category: 'tech',
        mode: 'online',
      ),
      event('esporte', now.add(const Duration(days: 23)), category: 'sports'),
    ];
    when(() => session.user).thenReturn(
      const UserProfile(
        id: 'user',
        name: 'Ana Silva',
        email: 'ana@corevent.com',
        birthDate: '2000-01-01',
      ),
    );
    when(
      () => events.list(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        search: any(named: 'search'),
        category: any(named: 'category'),
      ),
    ).thenAnswer(
      (invocation) async => EventPage(
        data: catalog
            .where(
              (e) =>
                  invocation.namedArguments[#category] == null ||
                  e.category == invocation.namedArguments[#category],
            )
            .toList(),
        meta: const EventPageMeta(page: 1, totalPages: 1),
      ),
    );
    when(() => favorites.list(any(), any())).thenAnswer(
      (invocation) async => EventPage(
        data: invocation.positionalArguments[1] == 'opened' ? [catalog[2]] : [],
        meta: const EventPageMeta(page: 1, totalPages: 1),
      ),
    );
    when(() => tickets.list(page: any(named: 'page'))).thenAnswer(
      (_) async => const TicketPage(
        data: [
          UserTicket(
            id: 'ticket',
            status: 'pending',
            ticketType: UserTicketType(id: 'type', name: 'Inteira', price: 50),
            event: UserTicketEvent(id: 'destaque', title: 'Evento destaque'),
            order: UserTicketOrder(id: 'order', status: 'paid'),
          ),
        ],
        meta: TicketPageMeta(page: 1, totalPages: 1),
      ),
    );
  });

  Future<void> open(
    WidgetTester tester, {
    double scale = 1,
    double width = 360,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    container = ProviderContainer(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(events),
        favoritesRepositoryProvider.overrideWithValue(favorites),
        ticketsRepositoryProvider.overrideWithValue(tickets),
        authSessionProvider.overrideWithValue(session),
      ],
    );
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: HomePage()),
        ),
        GoRoute(
          path: '/explore',
          builder: (_, state) => Scaffold(
            body: ExplorePage(
              discovery: EventDiscoveryFilter.fromQuery(
                state.uri.queryParameters,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/tickets',
          builder: (_, _) => const Scaffold(body: Text('Lista de ingressos')),
        ),
        GoRoute(
          path: '/profile/favorites',
          builder: (_, _) => const Scaffold(body: Text('Lista de favoritos')),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Minha conta')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reach(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      450,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Home não mostra atalho nem consulta ingressos', (tester) async {
    await open(tester);
    expect(find.text('Seus ingressos'), findsNothing);
    verifyNever(() => tickets.list(page: any(named: 'page')));
  });

  testWidgets('interesse abre Explorar com uma única consulta filtrada', (
    tester,
  ) async {
    await open(tester);
    await reach(tester, find.byType(HomeInterestGrid));
    final music = find.descendant(
      of: find.byType(HomeInterestGrid),
      matching: find.text('Música'),
    );
    await tester.ensureVisible(music);
    await tester.tap(music);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['category'],
      'music',
    );
    expect(container.read(exploreViewModelProvider).category, 'music');
    verify(
      () => events.list(page: 1, limit: 10, search: null, category: 'music'),
    ).called(1);
    verifyNever(
      () => events.list(page: 1, limit: 10, search: null, category: null),
    );
  });

  testWidgets('seção online abre somente eventos online e permite limpar', (
    tester,
  ) async {
    await open(tester);
    await reach(tester, find.text('Explorar eventos online'));
    await tester.tap(find.text('Explorar eventos online'));
    await tester.pumpAndSettle();
    expect(container.read(exploreViewModelProvider).events.map((e) => e.id), [
      'online',
    ]);
    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(container.read(exploreViewModelProvider).discovery.isEmpty, true);
    expect(router.routeInformationProvider.value.uri.queryParameters, {
      'discover': 'all',
    });
    expect(
      container.read(exploreViewModelProvider).events.length,
      catalog.length,
    );
  });

  testWidgets('favoritos têm acesso funcional e saudação fica fixa', (
    tester,
  ) async {
    await open(tester);
    final greetingY = tester.getTopLeft(find.text('Olá, Ana!')).dy;
    await reach(tester, find.text('Ver favoritos'));
    expect(tester.getTopLeft(find.text('Olá, Ana!')).dy, greetingY);
    await tester.tap(find.text('Ver favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Lista de favoritos'), findsOneWidget);
  });

  testWidgets('fim de semana transfere o período para Explorar', (
    tester,
  ) async {
    await open(tester);
    await reach(tester, find.text('Explorar o fim de semana'));
    await tester.tap(find.text('Explorar o fim de semana'));
    await tester.pumpAndSettle();
    final state = container.read(exploreViewModelProvider);
    expect(state.discovery, EventDiscoveryFilter.weekend(DateTime.now()));
    expect(state.events.every(state.discovery.matches), true);
    expect(state.events, isNotEmpty);
  });

  testWidgets('swipe mantém eventos e apresenta falha somente em toast', (
    tester,
  ) async {
    await open(tester);
    when(() => events.list(page: 1, limit: 50, search: null, category: null))
        .thenThrow(Exception('offline'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Evento destaque'), findsOneWidget);
    expect(find.text('Atualizando eventos'), findsNothing);
    expect(
      find.text('Não foi possível atualizar. Puxe para tentar novamente.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha das fontes pessoais não bloqueia os eventos', (
    tester,
  ) async {
    when(() => favorites.list(any(), any())).thenThrow(Exception('offline'));
    when(() => tickets.list(page: any(named: 'page')))
        .thenThrow(Exception('offline'));
    await open(tester);
    expect(find.text('Evento destaque'), findsOneWidget);
    expect(find.text('Seus ingressos'), findsNothing);
    await reach(
      tester,
      find.text('Não foi possível consultar seus favoritos.'),
    );
    expect(tester.takeException(), isNull);
  });

  for (final (width, scale) in [
    (320.0, 1.5),
    (320.0, 2.0),
    (390.0, 1.0),
    (1100.0, 1.0),
  ]) {
    testWidgets('redesign cabe em largura $width e fonte $scale', (
      tester,
    ) async {
      await open(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await reach(tester, find.text('Continuar em Explorar'));
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
      expect(
        tester.getTopLeft(find.text('Olá, Ana!')).dy,
        greaterThanOrEqualTo(0),
      );
    });
  }
}
