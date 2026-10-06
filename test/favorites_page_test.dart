import 'dart:async';

import 'package:corevent_mobile_app/core/theme/app_colors.dart';
import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/events/presentation/event_widgets.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/favorites/presentation/favorites_page.dart';
import 'package:corevent_mobile_app/features/ratings/data/rating_dtos.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remixicon/remixicon.dart';

class MockRatings extends Mock implements RatingsRepository {}

class MockFavorites extends Mock implements FavoritesRepository {}

class MockEvents extends Mock implements EventsRepository {}

EventSummary event(String id, {String? title, String? image}) => EventSummary(
  id: id,
  favoriteId: 'f$id',
  title: title ?? 'Festival $id',
  bannerUrl: image,
  startDate: DateTime(2026, 10, 1, 19),
  endDate: DateTime(2026, 10, 2),
  category: 'music',
  isAdultOnly: true,
  locationName: 'Arena de eventos',
  organizer: const EventOrganizer(name: 'Org'),
);
EventPage page(List<EventSummary> items, {int total = 1}) => EventPage(
  data: items,
  meta: EventPageMeta(page: 1, totalPages: total),
);

void main() {
  late MockFavorites repository;
  late MockEvents events;
  late MockRatings ratings;
  setUp(() {
    repository = MockFavorites();
    events = MockEvents();
    ratings = MockRatings();
    when(
      () => ratings.list(any()),
    ).thenAnswer((_) async => const RatedEventPage([], RatingPageMeta(1, 1)));
    when(() => repository.list(any(), any()))
        .thenAnswer((_) async => page([event('1'), event('2')]));
    when(() => events.detail(any()))
        .thenAnswer((_) async => throw Exception('offline'));
  });

  Future<void> open(
    WidgetTester tester, {
    double scale = 1,
    double width = 360,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = Size(width, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/profile/favorites',
      routes: [
        GoRoute(
          path: '/profile/favorites',
          builder: (_, _) => const FavoritesPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Conta')),
        ),
        GoRoute(
          path: '/explore',
          builder: (_, _) => const Scaffold(body: Text('Descobrir eventos')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(repository),
          eventsRepositoryProvider.overrideWithValue(events),
          ratingsRepositoryProvider.overrideWithValue(ratings),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (width, scale) in [
    (360.0, 1.5),
    (360.0, 2.0),
    (320.0, 2.0),
    (1000.0, 1.0),
  ]) {
    testWidgets('cards e filtros cabem com largura $width e fonte $scale', (
      tester,
    ) async {
      await open(tester, width: width, scale: scale);
      expect(find.byType(EventArtwork), findsWidgets);
      expect(find.text('Festival 1'), findsOneWidget);
      final before = tester.getTopLeft(find.text('Abertos'));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -380));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Abertos')), before);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'coração confirma sem abrir prévia e bloqueia só o item enviado',
    (tester) async {
      final removal = Completer<void>();
      when(() => repository.remove('f1')).thenAnswer((_) => removal.future);
      await open(tester);
      await tester.tap(find.byTooltip('Remover Festival 1 dos favoritos'));
      await tester.pumpAndSettle();
      expect(find.text('Remover favorito?'), findsOneWidget);
      verifyNever(() => events.detail(any()));
      await tester.tap(find.text('Remover'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Removendo Festival 1',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Remover Festival 2 dos favoritos',
              ),
            )
            .onPressed,
        isNotNull,
      );
      removal.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Festival 1'), findsNothing);
      expect(find.text('Festival 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('falha na remoção preserva card e mostra toast vermelho', (
    tester,
  ) async {
    when(() => repository.remove('f1')).thenThrow(Exception('offline'));
    await open(tester);
    await tester.tap(find.byTooltip('Remover Festival 1 dos favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(find.text('Festival 1'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      AppColors.error,
    );
    expect(
      find.text('Não foi possível remover o favorito. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('card abre e fecha prévia mantendo resumo em falha', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Festival 1'));
    await tester.pumpAndSettle();
    expect(find.text('Prévia do evento'), findsOneWidget);
    verify(() => events.detail('1')).called(1);
    await tester.tap(find.byTooltip('Fechar prévia'));
    await tester.pumpAndSettle();
    expect(find.text('Prévia do evento'), findsNothing);
    expect(find.text('Festival 1'), findsOneWidget);
  });

  testWidgets('swipe mantém cards e erro aparece só no toast', (tester) async {
    await open(tester);
    when(() => repository.list(1, 'opened')).thenThrow(Exception('offline'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    verify(() => repository.list(1, 'opened')).called(2);
    expect(find.text('Festival 1'), findsOneWidget);
    expect(find.text('Favoritos indisponíveis'), findsNothing);
    expect(
      find.text('Não foi possível carregar seus favoritos.'),
      findsOneWidget,
    );
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      AppColors.error,
    );
  });

  testWidgets('filtro troca com fade sequencial e vazio abre Explorar', (
    tester,
  ) async {
    when(() => repository.list(1, 'finished'))
        .thenAnswer((_) async => page([]));
    await open(tester);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-250, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrados'));
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.text('Festival 1'), findsOneWidget);
    expect(find.text('Nenhum evento encerrado salvo'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Festival 1'), findsNothing);
    expect(find.text('Nenhum evento encerrado salvo'), findsOneWidget);
    await tester.tap(find.text('Explorar eventos'));
    await tester.pumpAndSettle();
    expect(find.text('Descobrir eventos'), findsOneWidget);
  });

  testWidgets('título longo e imagem ausente mantêm conteúdo alcançável', (
    tester,
  ) async {
    const title =
        'Festival de música, gastronomia e experiências para toda a família na cidade';
    when(() => repository.list(1, 'opened'))
        .thenAnswer((_) async => page([event('1', title: title)]));
    await open(tester, width: 320, scale: 2);
    expect(find.text(title), findsOneWidget);
    expect(tester.widget<Text>(find.text(title)).maxLines, isNull);
    expect(find.byIcon(RemixIcons.ticket_line), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Arena de eventos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'falha inicial permite tentar novamente sem movimento obrigatório',
    (tester) async {
      when(() => repository.list(1, 'opened')).thenThrow(Exception('offline'));
      await open(tester, reduced: true);
      expect(find.text('Favoritos indisponíveis'), findsOneWidget);
      when(() => repository.list(1, 'opened'))
          .thenAnswer((_) async => page([]));
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum evento aberto salvo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
