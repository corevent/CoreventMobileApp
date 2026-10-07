import 'dart:async';

import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/presentation/event_widgets.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/favorites/presentation/event_favorite_button.dart';
import 'package:corevent_mobile_app/features/ratings/data/rating_dtos.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_repository.dart';
import 'package:corevent_mobile_app/features/ratings/presentation/rating_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavorites extends Mock implements FavoritesRepository {}

class MockRatings extends Mock implements RatingsRepository {}

const ratedEvent = RatedEvent(
  eventId: '1',
  eventTitle: 'Festival da Cidade',
  userRating: 0,
  averageRating: 4.5,
);

void main() {
  late MockFavorites favorites;
  late MockRatings ratings;
  setUp(() {
    favorites = MockFavorites();
    ratings = MockRatings();
    when(() => favorites.list(any(), any())).thenAnswer(
      (_) async => const EventPage(
        data: [],
        meta: EventPageMeta(page: 1, totalPages: 1),
      ),
    );
    when(
      () => ratings.list(any()),
    ).thenAnswer((_) async => const RatedEventPage([], RatingPageMeta(1, 1)));
  });

  Future<void> open(
    WidgetTester tester, {
    double scale = 1,
    Widget? content,
  }) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(favorites),
          ratingsRepositoryProvider.overrideWithValue(ratings),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: content ?? const EventRatingSection(event: ratedEvent),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scale in [1.5, 2.0]) {
    testWidgets('estrelas exigem salvar e formulário cabe com fonte $scale', (
      tester,
    ) async {
      when(() => ratings.save('1', 4, id: null))
          .thenAnswer((_) async => const RatingData('r1', '1', 4));
      await open(tester, scale: scale);
      expect(find.text('4.5'), findsOneWidget);
      await tester.tap(find.text('Avaliar evento'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Selecionar 4 estrelas'));
      await tester.pumpAndSettle();
      verifyNever(() => ratings.save(any(), any(), id: any(named: 'id')));
      expect(find.text('Sua nota: 4 de 5'), findsOneWidget);
      await tester.ensureVisible(find.text('Salvar avaliação'));
      await tester.tap(find.text('Salvar avaliação'));
      await tester.pumpAndSettle();
      expect(find.text('Editar avaliação'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'envio bloqueia estrelas, fechar e voltar; falha preserva escolha',
    (tester) async {
      final response = Completer<RatingData>();
      when(() => ratings.save('1', 3, id: null))
          .thenAnswer((_) => response.future);
      await open(tester);
      await tester.tap(find.text('Avaliar evento'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Selecionar 3 estrelas'));
      await tester.pump();
      await tester.tap(find.text('Salvar avaliação'));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Fechar avaliação',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Selecionar 5 estrelas',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Sua nota: 3 de 5'), findsOneWidget);
      response.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Sua nota: 3 de 5'), findsOneWidget);
      expect(
        find.text('Não foi possível salvar a avaliação. Tente novamente.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Fechar avaliação',
              ),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'editar e remover usam confirmação explícita e sincronizam seção',
    (tester) async {
      when(() => ratings.list(1)).thenAnswer(
        (_) async => const RatedEventPage([
          RatedEvent(
            eventId: '1',
            eventTitle: 'Festival',
            userRating: 4,
            ratingId: 'r1',
          ),
        ], RatingPageMeta(1, 1)),
      );
      when(() => ratings.remove('r1')).thenAnswer((_) async {});
      await open(tester);
      await tester.tap(find.text('Editar avaliação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover avaliação'));
      await tester.pumpAndSettle();
      verifyNever(() => ratings.remove(any()));
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover avaliação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(find.text('Avaliar evento'), findsOneWidget);
      verify(() => ratings.remove('r1')).called(1);
    },
  );

  testWidgets(
    'coração tem ação independente do card e permite foco por teclado',
    (tester) async {
      var opened = 0;
      when(() => favorites.create('1')).thenAnswer((_) async => 'f1');
      await open(
        tester,
        content: EventSummaryCard(
          event: EventSummary(
            id: '1',
            title: 'Festival',
            startDate: DateTime(2026, 10),
            endDate: DateTime(2026, 11),
            category: 'music',
            isAdultOnly: false,
            locationName: 'Arena',
            organizer: const EventOrganizer(name: 'Org'),
          ),
          onTap: () => opened++,
        ),
      );
      await tester.tap(find.byType(EventFavoriteButton));
      await tester.pumpAndSettle();
      expect(opened, 0);
      expect(find.byTooltip('Favoritado'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);
      await tester.tap(find.text('Festival'));
      expect(opened, 1);
    },
  );

  testWidgets('avaliação sem id aparece sem ação de edição', (tester) async {
    when(() => ratings.list(1)).thenAnswer(
      (_) async => const RatedEventPage([
        RatedEvent(eventId: '1', eventTitle: 'Festival', userRating: 5),
      ], RatingPageMeta(1, 1)),
    );
    await open(tester);
    expect(find.text('Sua nota: 5 de 5'), findsOneWidget);
    expect(find.text('Editar avaliação'), findsNothing);
    expect(find.text('Avaliar evento'), findsNothing);
  });
}
