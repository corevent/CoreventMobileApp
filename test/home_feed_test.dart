import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/domain/event_discovery_filter.dart';
import 'package:corevent_mobile_app/features/events/domain/event_visibility.dart';
import 'package:corevent_mobile_app/features/home/domain/home_feed.dart';
import 'package:flutter_test/flutter_test.dart';

const organizer = EventOrganizer(name: 'Equipe Corevent');

EventSummary event(
  String id,
  DateTime start, {
  bool adult = false,
  String category = 'music',
  String? mode,
}) => EventSummary(
  id: id,
  title: 'Evento $id',
  startDate: start,
  endDate: start.add(const Duration(hours: 3)),
  category: category,
  locationType: mode,
  isAdultOnly: adult,
  locationName: 'Arena',
  organizer: organizer,
);

void main() {
  test('maioridade respeita o aniversário e falha fechada', () {
    final now = DateTime(2026, 9, 25, 12);
    expect(isAdult('2008-09-25', now), true);
    expect(isAdult('2008-09-26', now), false);
    expect(isAdult(null, now), false);
    expect(isAdult('inválida', now), false);
  });

  test('remove restritos, encerrados e duplicados e ordena por início', () {
    final now = DateTime(2026, 9, 25, 12);
    final later = event('later', now.add(const Duration(days: 4)));
    final sooner = event('sooner', now.add(const Duration(days: 1)));
    final restricted = event(
      'adult',
      now.add(const Duration(days: 2)),
      adult: true,
    );
    final ended = event('ended', now.subtract(const Duration(days: 3)));
    final visible = visibleEvents(
      [later, sooner, later, restricted, ended],
      birthDate: null,
      now: now,
    );
    expect(visible.map((item) => item.id), ['sooner', 'later']);
  });

  test('distribui cada evento em apenas uma seção', () {
    final now = DateTime(2026, 9, 25, 12);
    final events = [
      for (var day = 1; day <= 7; day++)
        event('$day', now.add(Duration(days: day))),
    ];
    final sections = HomeSections.from(events, now);
    expect(sections.featured?.id, '1');
    final ids = [
      sections.featured!.id,
      for (final section in sections.sections)
        ...section.events.map((e) => e.id),
    ];
    expect(ids.toSet().length, ids.length);
    expect(
      sections.sections.every(
        (s) => s.events.isNotEmpty && s.events.length <= 2,
      ),
      true,
    );
  });

  test('catálogo pequeno mantém destaque e uma única seção adicional', () {
    final now = DateTime(2026, 9, 25, 12);
    final ongoing = EventSummary(
      id: 'ongoing',
      title: 'Em andamento',
      startDate: now.subtract(const Duration(hours: 2)),
      endDate: now.add(const Duration(hours: 2)),
      category: 'music',
      isAdultOnly: false,
      locationName: 'Arena',
      organizer: organizer,
    );
    final sections = HomeSections.from([
      ongoing,
      event('outro', now.subtract(const Duration(hours: 1))),
      event('futuro', now.add(const Duration(days: 1))),
    ], now);
    expect(sections.featured!.id, 'ongoing');
    expect(sections.sections.single.title, 'Mais experiências');
    expect(sections.sections.single.events.map((e) => e.id), [
      'outro',
      'futuro',
    ]);
  });

  test(
    'organiza favoritos, fim de semana, interesses e online sem repetição',
    () {
      final now = DateTime(2026, 9, 28, 12);
      final saved = event(
        'saved',
        DateTime(2026, 10, 9),
        category: 'gastronomy',
      );
      final feed = HomeSections.from(
        [
          event('hero', DateTime(2026, 10, 1)),
          event('weekend', DateTime(2026, 10, 3)),
          saved,
          event('music', DateTime(2026, 10, 13)),
          event('art', DateTime(2026, 10, 14), category: 'art_culture'),
          event(
            'online',
            DateTime(2026, 10, 15),
            category: 'tech',
            mode: 'online',
          ),
          event('sport', DateTime(2026, 10, 16), category: 'sports'),
        ],
        now,
        saved: [saved],
      );
      expect(feed.featured!.id, 'hero');
      expect(feed.sections.map((s) => s.id), [
        'saved',
        'weekend',
        'category-music',
        'category-art_culture',
        'online',
        'more',
      ]);
      expect(feed.sections.first.favorites, true);
      expect(feed.sections.first.events.single.id, 'saved');
      final ids = [
        feed.featured!.id,
        for (final s in feed.sections) ...s.events.map((e) => e.id),
      ];
      expect(ids.toSet().length, ids.length);
      for (final section in feed.sections.where((s) => !s.filter.isEmpty)) {
        expect(section.events.every(section.filter.matches), true);
      }
    },
  );

  test('fim de semana usa sexta até segunda exclusiva, incluindo eventos em andamento', () {
    for (final day in [28, 29, 30]) {
      expect(
        EventDiscoveryFilter.weekend(DateTime(2026, 9, day)).from,
        DateTime(2026, 10, 2),
      );
    }
    for (final day in [2, 3, 4]) {
      final filter = EventDiscoveryFilter.weekend(DateTime(2026, 10, day));
      expect(filter.from, DateTime(2026, 10, 2));
      expect(filter.until, DateTime(2026, 10, 5));
      expect(filter.matches(event('sunday', DateTime(2026, 10, 4, 23))), true);
      expect(filter.matches(event('monday', DateTime(2026, 10, 5))), false);
      expect(EventDiscoveryFilter.fromQuery(filter.query), filter);
    }
  });

  test('omissão de seções vazias e eventos encerrados', () {
    final feed = HomeSections.from([
      event('ended', DateTime(2026, 9, 1)),
    ], DateTime(2026, 9, 28));
    expect(feed.featured, isNull);
    expect(feed.sections, isEmpty);
  });
}
