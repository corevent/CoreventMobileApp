import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/ratings/data/rating_dtos.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_repository.dart';
import 'package:corevent_mobile_app/features/ratings/presentation/ratings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatingsRepository extends Mock implements RatingsRepository {}

class MockEventsRepository extends Mock implements EventsRepository {}

const editable = RatedEvent(
  eventId: 'e1',
  eventTitle: 'Festival do Centro',
  userRating: 4,
  ratingId: 'r1',
);
const readOnly = RatedEvent(
  eventId: 'e2',
  eventTitle: 'Festival do Bairro',
  userRating: 3,
);

RatedEventPage page(List<RatedEvent> events) =>
    RatedEventPage(events, const RatingPageMeta(1, 1));

void main() {
  late MockRatingsRepository ratings;
  late MockEventsRepository events;

  setUp(() {
    ratings = MockRatingsRepository();
    events = MockEventsRepository();
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ratingsRepositoryProvider.overrideWithValue(ratings),
          eventsRepositoryProvider.overrideWithValue(events),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const RatingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista vazia orienta e pode atualizar', (tester) async {
    when(() => ratings.list(1)).thenAnswer((_) async => page([]));
    await show(tester);
    expect(find.text('Você ainda não avaliou eventos.'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    verify(() => ratings.list(1)).called(2);
  });

  testWidgets('falha inicial oferece nova tentativa e recupera lista', (
    tester,
  ) async {
    var calls = 0;
    when(() => ratings.list(1)).thenAnswer((_) async {
      if (++calls == 1) throw Exception('offline');
      return page([editable]);
    });
    await show(tester);
    expect(
      find.text('Não foi possível consultar suas avaliações.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Festival do Centro'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets(
    'só avaliação identificada permite editar; erro ao abrir informa',
    (tester) async {
      when(() => ratings.list(1))
          .thenAnswer((_) async => page([editable, readOnly]));
      when(() => events.detail('e1')).thenThrow(Exception('offline'));
      await show(tester);
      expect(find.text('Festival do Centro'), findsOneWidget);
      expect(find.text('Festival do Bairro'), findsOneWidget);
      expect(find.text('Editar avaliação'), findsOneWidget);
      await tester.tap(find.text('Editar avaliação'));
      await tester.pumpAndSettle();
      expect(find.text('Sua avaliação'), findsOneWidget);
      expect(find.text('Sua nota: 4 de 5'), findsWidgets);
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Festival do Centro'));
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível abrir este evento. Tente novamente.'),
        findsOneWidget,
      );
      verify(() => events.detail('e1')).called(1);
    },
  );
}
