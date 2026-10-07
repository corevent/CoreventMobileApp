import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/presentation/event_widgets.dart';
import 'package:corevent_mobile_app/features/ratings/presentation/rating_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';

EventSummary event(double average) => EventSummary(
  id: '1',
  title: 'Festival da Cidade com música, gastronomia e apresentações culturais',
  startDate: DateTime(2026, 10),
  endDate: DateTime(2026, 11),
  category: 'music',
  isAdultOnly: true,
  locationName: 'Centro de eventos da cidade, avenida principal, número 1500',
  organizer: const EventOrganizer(name: 'Corevent'),
  averageRating: average,
  ratingCount: 1234,
);

void main() {
  setUpAll(() async {
    final font = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont_wght.ttf'),
      );
    await font.load();
    final icons = FontLoader('packages/remixicon/remix')
      ..addFont(rootBundle.load('packages/remixicon/fonts/remix.ttf'));
    await icons.load();
  });
  for (final featured in [false, true]) {
    for (final (width, scale) in [
      (320.0, 1.0),
      (360.0, 1.0),
      (360.0, 1.5),
      (320.0, 2.0),
      (1000.0, 2.0),
    ]) {
      testWidgets(
        'card destaque=$featured largura=$width fonte=$scale comporta todos os elementos',
        (tester) async {
          tester.view.physicalSize = Size(width, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EventSummaryCard(
                      event: event(4.45),
                      featured: featured,
                      action: IconButton(
                        tooltip: 'Favoritar',
                        onPressed: () {},
                        icon: const Icon(RemixIcons.heart_line),
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('4.5 (1234)'), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('Média das avaliações: 4.5 de 5')),
            findsWidgets,
          );
          expect(tester.takeException(), isNull);
          for (final (icon, label) in [
            (RemixIcons.star_fill, '4.5 (1234)'),
            (
              RemixIcons.calendar_event_line,
              eventDate(
                tester.element(find.byType(EventSummaryCard)),
                event(4.45).startDate,
              ),
            ),
            (RemixIcons.map_pin_line, event(4.45).locationName),
          ]) {
            final textTop = tester.getTopLeft(find.text(label)).dy;
            expect(
              tester.getCenter(find.byIcon(icon)).dy,
              closeTo(textTop + 12 * scale * 1.4 / 2, .1),
            );
          }
          expect(
            tester.getSize(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Favoritar',
              ),
            ),
            const Size(48, 48),
          );
          final location = tester.widget<Text>(
            find.text(event(4.45).locationName),
          );
          expect(location.maxLines, isNull);
          expect(location.overflow, isNull);
          final favorite = find.byWidgetPredicate(
            (w) => w is IconButton && w.tooltip == 'Favoritar',
          );
          expect(
            tester.getCenter(find.text('Música')).dy,
            closeTo(tester.getCenter(favorite).dy, .1),
          );
          final artwork = find.byType(EventArtwork);
          final artworkRect = tester.getRect(artwork);
          final cardRect = tester.getRect(find.byType(EventSummaryCard));
          expect(artworkRect.width, closeTo(cardRect.width, .1));
          expect(
            artworkRect.height / artworkRect.width,
            closeTo(featured ? 9 / 16 : .5, .001),
          );
          expect(
            tester.getTopLeft(find.text(event(4.45).title)).dy -
                artworkRect.bottom,
            closeTo(12, .1),
          );
          expect(find.text('Corevent'), findsNothing);
          semantics.dispose();
        },
      );
    }
  }

  testWidgets(
    'categoria longa e favorito ocupado mantêm alinhamento e altura',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var busy = false;
      late StateSetter update;
      final summary = EventSummary(
        id: '1',
        title: 'Festival',
        startDate: DateTime(2026, 10),
        endDate: DateTime(2026, 11),
        category: 'religious_spiritual',
        isAdultOnly: true,
        locationName: 'Arena',
        organizer: const EventOrganizer(name: 'Corevent'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      update = setState;
                      return EventSummaryCard(
                        event: summary,
                        onTap: () {},
                        action: IconButton(
                          key: const ValueKey('favorite'),
                          onPressed: busy ? null : () {},
                          icon: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(RemixIcons.heart_line),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final height = tester.getSize(find.byType(EventSummaryCard)).height;
      final buttonY = tester
          .getCenter(find.byKey(const ValueKey('favorite')))
          .dy;
      expect(
        tester.getCenter(find.text('Religioso e espiritual')).dy,
        closeTo(buttonY, .1),
      );
      update(() => busy = true);
      await tester.pump();
      expect(tester.getSize(find.byType(EventSummaryCard)).height, height);
      expect(
        tester.getCenter(find.byKey(const ValueKey('favorite'))).dy,
        buttonY,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sem nota apresenta estado vazio em vez de zero estrelas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventSummaryCard(
            event: event(0),
            action: const SizedBox.shrink(),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Sem avaliações'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  test('listagem lê média decimal numérica, textual e nula', () {
    final json = {
      'id': '1',
      'title': 'Festival',
      'startDate': '2026-10-01T00:00:00Z',
      'endDate': '2026-10-02T00:00:00Z',
      'category': 'music',
      'isAdultOnly': false,
      'locationName': 'Arena',
      'organizer': {'name': 'Corevent'},
    };
    for (final value in [4.5, '4.5']) {
      expect(
        EventSummary.fromJson({...json, 'averageRating': value}).averageRating,
        4.5,
      );
    }
    expect(
      EventSummary.fromJson({...json, 'averageRating': null}).averageRating,
      0,
    );
    for (final count in [1234, '1234']) {
      expect(
        EventSummary.fromJson({...json, 'ratingCount': count}).ratingCount,
        1234,
      );
      expect(
        EventDetail.fromJson({...json, 'ratingCount': count}).ratingCount,
        1234,
      );
    }
    expect(EventSummary.fromJson(json).ratingCount, isNull);
    expect(
      EventSummary.fromJson({...json, 'ratingCount': -1}).ratingCount,
      isNull,
    );
  });

  test('média usa ponto e quantidade somente quando disponível', () {
    expect(ratingAverage(4.8, count: 1234), '4.8 (1234)');
    expect(ratingAverage(4.8), '4.8');
    expect(ratingAverage(0), 'Sem avaliações');
    expect(ratingAverage(double.nan), 'Sem avaliações');
  });
}
