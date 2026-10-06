import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/events/presentation/event_widgets.dart';
import 'package:corevent_mobile_app/features/explore/presentation/explore_page.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/home/presentation/home_page.dart';
import 'package:corevent_mobile_app/features/ratings/data/rating_dtos.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_repository.dart';
import 'package:corevent_mobile_app/features/tickets/data/ticket_dtos.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavorites extends Mock implements FavoritesRepository {}

class MockRatings extends Mock implements RatingsRepository {}

class MockEventsRepository extends Mock implements EventsRepository {}

class MockSession extends Mock implements AuthSession {}

class MockTickets extends Mock implements TicketsRepository {}

void main() {
  late MockEventsRepository repository;
  late MockSession session;
  late MockFavorites favorites;
  late MockRatings ratings;
  late MockTickets tickets;

  final start = DateTime.now().add(const Duration(days: 4));
  final summary = EventSummary(
    id: 'evt-1',
    title: 'Festival da Cidade',
    startDate: start,
    endDate: start.add(const Duration(hours: 3)),
    category: 'music',
    isAdultOnly: false,
    locationName: 'Praça Central',
    organizer: const EventOrganizer(name: 'Corevent'),
  );

  setUp(() {
    repository = MockEventsRepository();
    session = MockSession();
    favorites = MockFavorites();
    ratings = MockRatings();
    tickets = MockTickets();
    when(() => tickets.list(page: any(named: 'page'))).thenAnswer(
      (_) async => const TicketPage(
        data: [],
        meta: TicketPageMeta(page: 1, totalPages: 1),
      ),
    );
    when(() => favorites.list(any(), any())).thenAnswer(
      (_) async => const EventPage(
        data: [],
        meta: EventPageMeta(page: 1, totalPages: 1),
      ),
    );
    when(
      () => ratings.list(any()),
    ).thenAnswer((_) async => const RatedEventPage([], RatingPageMeta(1, 1)));
    when(() => session.user).thenReturn(
      const UserProfile(id: '1', name: 'Ana Silva', email: 'ana@corevent.com'),
    );
    when(() => session.logout()).thenAnswer((_) async {});
    when(
      () => repository.list(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        search: any(named: 'search'),
        category: any(named: 'category'),
      ),
    ).thenAnswer(
      (_) async => EventPage(
        data: [summary],
        meta: const EventPageMeta(page: 1, totalPages: 1),
      ),
    );
    when(() => repository.detail('evt-1')).thenAnswer(
      (_) async => EventDetail(
        id: 'evt-1',
        title: 'Festival da Cidade',
        startDate: start,
        endDate: start.add(const Duration(hours: 3)),
        category: 'music',
        isAdultOnly: false,
        locationName: 'Praça Central',
        organizer: const EventOrganizer(name: 'Corevent'),
        description: 'Música ao vivo no centro da cidade.',
      ),
    );
  });

  Future<void> open(
    WidgetTester tester, {
    double scale = 1,
    bool explore = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsRepositoryProvider.overrideWithValue(repository),
          authSessionProvider.overrideWithValue(session),
          favoritesRepositoryProvider.overrideWithValue(favorites),
          ratingsRepositoryProvider.overrideWithValue(ratings),
          ticketsRepositoryProvider.overrideWithValue(tickets),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: explore ? const ExplorePage() : const HomePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra descoberta e abre a prévia real', (tester) async {
    await open(tester);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.text('Para sua próxima saída'), findsOneWidget);
    expect(find.text('Festival da Cidade'), findsOneWidget);
    await tester.tap(find.byType(EventSummaryCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Prévia do evento'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Música ao vivo no centro da cidade.'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Música ao vivo no centro da cidade.'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar prévia'));
    await tester.pumpAndSettle();
    expect(find.text('Prévia do evento'), findsNothing);
  });

  testWidgets('busca e categoria consultam a API em Explorar', (tester) async {
    await open(tester, explore: true);
    await tester.enterText(find.byType(TextField), 'festival');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Resultados'), findsOneWidget);
    verify(
      () => repository.list(
        page: 1,
        limit: 10,
        search: 'festival',
        category: null,
      ),
    ).called(1);
    await tester.tap(find.text('Música').first);
    await tester.pumpAndSettle();
    verify(
      () => repository.list(
        page: 1,
        limit: 10,
        search: 'festival',
        category: 'music',
      ),
    ).called(1);
  });

  testWidgets('Home mostra saudação compacta e não exibe busca', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byTooltip('Abrir perfil'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Categorias'), findsNothing);
  });

  testWidgets('títulos da Home começam junto aos cards', (tester) async {
    await open(tester);
    final titleX = tester.getTopLeft(find.text('Para sua próxima saída')).dx;
    final cardX = tester.getTopLeft(find.byType(EventSummaryCard).first).dx;
    expect(titleX, closeTo(cardX, 1));
  });

  testWidgets('busca de Explorar permanece fixa durante a rolagem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await open(tester, explore: true);
    expect(find.text('Encontre experiências do seu jeito.'), findsNothing);
    final searchY = tester.getTopLeft(find.byType(TextField)).dy;
    final categoryX = tester.getTopLeft(find.text('Categorias')).dx;
    expect(categoryX, closeTo(tester.getTopLeft(find.byType(TextField)).dx, 1));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(TextField)).dy, closeTo(searchY, 1));
    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );
  });

  testWidgets('erro inicial apresenta ação para tentar de novo', (
    tester,
  ) async {
    when(
      () => repository.list(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        search: any(named: 'search'),
        category: any(named: 'category'),
      ),
    ).thenThrow(Exception('offline'));
    await open(tester);
    expect(find.text('Eventos indisponíveis'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('lista vazia mostra mensagem e atualização', (tester) async {
    when(
      () => repository.list(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        search: any(named: 'search'),
        category: any(named: 'category'),
      ),
    ).thenAnswer(
      (_) async => const EventPage(
        data: [],
        meta: EventPageMeta(page: 1, totalPages: 1),
      ),
    );
    await open(tester);
    expect(find.text('Ainda não há eventos'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
  });

  testWidgets('prévia preserva resumo e permite repetir após erro', (
    tester,
  ) async {
    var attempts = 0;
    when(() => repository.detail('evt-1')).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw Exception('offline');
      return EventDetail(
        id: 'evt-1',
        title: 'Festival da Cidade',
        startDate: start,
        endDate: start.add(const Duration(hours: 3)),
        category: 'music',
        isAdultOnly: false,
        locationName: 'Praça Central',
        organizer: const EventOrganizer(name: 'Corevent'),
        description: 'Descrição recuperada.',
      );
    });
    await open(tester);
    await tester.tap(find.byType(EventSummaryCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Festival da Cidade'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Não foi possível carregar a descrição deste evento.'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.scrollUntilVisible(
      find.text('Tentar novamente'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Descrição recuperada.'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Descrição recuperada.'), findsOneWidget);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('fonte ${scale}x não causa overflow em largura de celular', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await open(tester, scale: scale);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Festival da Cidade'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Festival da Cidade'), findsOneWidget);
      await tester.ensureVisible(find.byType(EventSummaryCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EventSummaryCard).first);
      await tester.pumpAndSettle();
      expect(find.text('Prévia do evento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
