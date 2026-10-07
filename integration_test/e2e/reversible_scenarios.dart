import 'package:corevent_mobile_app/app/router.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/explore/presentation/explore_view_model.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/favorites/presentation/event_favorites_view_model.dart';
import 'package:corevent_mobile_app/features/favorites/presentation/favorites_view_model.dart';
import 'package:corevent_mobile_app/features/profile/data/profile_repository.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_forms_view_model.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_repository.dart';
import 'package:corevent_mobile_app/features/ratings/presentation/event_ratings_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/live_harness.dart';

Future<void> _openPreview(
  WidgetTester tester,
  ProviderContainer container,
  String eventId,
) async {
  final event = await container.read(eventsRepositoryProvider).detail(eventId);
  container.read(routerProvider).go('/explore');
  await tester.pumpAndSettle();
  await enterLiveText(tester, find.byType(TextField).first, event.title);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await pumpUntil(
    tester,
    () => !container.read(exploreViewModelProvider).loading,
  );
  expect(
    container.read(exploreViewModelProvider).events.any((e) => e.id == eventId),
    isTrue,
    reason: 'O evento de E2E deve estar aberto e pesquisável.',
  );
  final card = find.text(event.title).last;
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
  expect(find.text('Prévia do evento'), findsOneWidget);
}

Future<void> _tapPreviewAction(WidgetTester tester, String label) async {
  final sheet = find.byType(DraggableScrollableSheet);
  expect(sheet, findsOneWidget);
  final scrollable = find.descendant(
    of: sheet,
    matching: find.byType(Scrollable),
  );
  final action = find.descendant(of: sheet, matching: find.text(label));
  for (
    var attempt = 0;
    attempt < 30 && action.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(scrollable, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  expect(
    action.hitTestable(),
    findsOneWidget,
    reason: 'A ação deve estar visível e tocável dentro da prévia.',
  );
  await tester.tap(action.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _waitForRatingWrite(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pump();
  await pumpUntil(
    tester,
    () => !container
        .read(eventRatingsViewModelProvider)
        .busy
        .contains(e2eEventId),
  );
}

void registerReversibleTests() {
  setUpAll(() async {
    validateLiveConfiguration(needsEvent: true);
    await initializeDateFormatting('pt_BR');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
  setUp(clearLiveSession);
  tearDown(clearLiveSession);

  testWidgets('favorito real é criado e removido', (tester) async {
    final container = await openLiveApp(tester);
    var attemptedCreate = false;
    try {
      await loginLive(tester, container);
      final favorites = container.read(favoritesRepositoryProvider);
      final before = await favorites.list(1, 'opened');
      expect(
        before.data.any((e) => e.id == e2eEventId),
        isFalse,
        reason: 'Reserve um evento ainda não favoritado para a conta E2E.',
      );
      await _openPreview(tester, container, e2eEventId);
      await pumpUntil(tester, () {
        final state = container.read(eventFavoritesViewModelProvider);
        return state.loaded || state.error != null;
      });
      expect(container.read(eventFavoritesViewModelProvider).error, isNull);
      await tester.ensureVisible(find.text('Favoritar').last);
      attemptedCreate = true;
      await tester.tap(find.text('Favoritar').last);
      await tester.pump();
      await pumpUntil(
        tester,
        () => !container
            .read(eventFavoritesViewModelProvider)
            .busy
            .contains(e2eEventId),
      );
      final after = await favorites.list(1, 'opened');
      final saved = after.data.where((e) => e.id == e2eEventId).toList();
      expect(saved, hasLength(1));
      final createdId = saved.single.favoriteId;
      expect(createdId, isNotNull);
      await tester.tap(find.byTooltip('Fechar prévia'));
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/profile/favorites');
      await tester.pumpAndSettle();
      await pumpUntil(tester, () {
        final state = container.read(favoritesViewModelProvider);
        return !state.loading && (state.hasLoaded || state.error != null);
      });
      expect(container.read(favoritesViewModelProvider).error, isNull);
      expect(find.text(saved.single.title), findsWidgets);
      final remove = find.byTooltip(
        'Remover ${saved.single.title} dos favoritos',
      );
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover').last);
      await tester.pump();
      await pumpUntil(
        tester,
        () => container.read(favoritesViewModelProvider).removingIds.isEmpty,
      );
      final cleaned = await favorites.list(1, 'opened');
      expect(cleaned.data.any((e) => e.id == e2eEventId), isFalse);
      attemptedCreate = false;
    } finally {
      try {
        if (attemptedCreate) {
          final favorites = container.read(favoritesRepositoryProvider);
          final remaining = await favorites.list(1, 'opened');
          for (final event in remaining.data.where((e) => e.id == e2eEventId)) {
            if (event.favoriteId != null) {
              await favorites.remove(event.favoriteId!);
            }
          }
        }
      } finally {
        await closeLiveApp(tester, container);
      }
    }
  });

  testWidgets('dados pessoais reais são editados e restaurados', (
    tester,
  ) async {
    final container = await openLiveApp(tester);
    String? originalName;
    String? originalPhone;
    var attemptedSave = false;
    try {
      await loginLive(tester, container);
      final original = container.read(authSessionProvider).user!;
      originalName = original.name;
      originalPhone = original.phoneNumber;
      container.read(routerProvider).go('/profile/details');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      const changed = 'Corevent E2E Temporário';
      await enterLiveText(tester, find.byType(TextField).first, changed);
      final saveButton = find.widgetWithText(
        ElevatedButton,
        'Salvar alterações',
      );
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNotNull);
      attemptedSave = true;
      await tester.tap(find.text('Salvar alterações'));
      await pumpUntil(
        tester,
        () =>
            container.read(authSessionProvider).user?.name == changed ||
            container.read(detailsViewModelProvider).error != null,
      );
      expect(container.read(detailsViewModelProvider).error, isNull);
      expect(container.read(authSessionProvider).user?.name, changed);
      expect(find.text(changed), findsWidgets);
    } finally {
      try {
        if (attemptedSave && originalName != null) {
          await container
              .read(profileRepositoryProvider)
              .updateDetails(originalName, originalPhone ?? '');
        }
      } finally {
        await closeLiveApp(tester, container);
      }
    }
  });

  testWidgets('avaliação real é criada, editada e removida', (tester) async {
    final container = await openLiveApp(tester);
    var attemptedCreate = false;
    String? createdId;
    try {
      await loginLive(tester, container);
      final ratings = container.read(ratingsRepositoryProvider);
      final before = await ratings.list(1);
      expect(
        before.data.any((r) => r.eventId == e2eEventId),
        isFalse,
        reason: 'A conta E2E precisa começar sem avaliação desse evento.',
      );
      await _openPreview(tester, container, e2eEventId);
      // The section is built lazily by the panel's ListView.
      await _tapPreviewAction(tester, 'Avaliar evento');
      await tester.tap(find.byTooltip('Selecionar 4 estrelas'));
      await tester.pump();
      attemptedCreate = true;
      await tester.tap(find.text('Salvar avaliação'));
      await _waitForRatingWrite(tester, container);
      final created = await ratings.list(1);
      final match = created.data.where((r) => r.eventId == e2eEventId);
      expect(match, hasLength(1));
      createdId = container
          .read(eventRatingsViewModelProvider)
          .events[e2eEventId]
          ?.ratingId;
      expect(createdId, isNotNull);
      await _tapPreviewAction(tester, 'Editar avaliação');
      await tester.tap(find.byTooltip('Selecionar 5 estrelas'));
      await tester.pump();
      await tester.tap(find.text('Salvar avaliação'));
      await _waitForRatingWrite(tester, container);
      final edited = await ratings.list(1);
      expect(
        edited.data.singleWhere((r) => r.eventId == e2eEventId).userRating,
        5,
      );
      await _tapPreviewAction(tester, 'Editar avaliação');
      await tester.tap(find.text('Remover avaliação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover').last);
      await _waitForRatingWrite(tester, container);
      final removed = await ratings.list(1);
      expect(removed.data.any((r) => r.eventId == e2eEventId), isFalse);
      attemptedCreate = false;
    } finally {
      try {
        if (attemptedCreate) {
          final ratings = container.read(ratingsRepositoryProvider);
          final remaining = await ratings.list(1);
          if (remaining.data.any((r) => r.eventId == e2eEventId)) {
            final id =
                createdId ??
                container
                    .read(eventRatingsViewModelProvider)
                    .events[e2eEventId]
                    ?.ratingId;
            if (id == null) {
              throw StateError(
                'A API não retornou o ID da avaliação; limpeza automática impossível.',
              );
            }
            try {
              await ratings.remove(id);
            } on DioException catch (error) {
              if (error.response?.statusCode != 404) rethrow;
            }
          }
        }
      } finally {
        await closeLiveApp(tester, container);
      }
    }
  });
}
