import '../../events/data/event_dtos.dart';
import '../../events/domain/event_catalog.dart';
import '../../events/domain/event_discovery_filter.dart';

const homeInterests = [
  'music',
  'art_culture',
  'gastronomy',
  'sports',
  'tech',
  'education',
];

class HomeSection {
  const HomeSection({
    required this.id,
    required this.title,
    required this.events,
    required this.actionLabel,
    this.filter = const EventDiscoveryFilter(),
    this.favorites = false,
  });
  final String id;
  final String title;
  final List<EventSummary> events;
  final String actionLabel;
  final EventDiscoveryFilter filter;
  final bool favorites;
}

class HomeSections {
  const HomeSections({required this.featured, required this.sections});
  final EventSummary? featured;
  final List<HomeSection> sections;

  factory HomeSections.from(
    List<EventSummary> events,
    DateTime now, {
    List<EventSummary> saved = const [],
  }) {
    final all = <String, EventSummary>{};
    for (final event in [...events, ...saved]) {
      if (event.endDate.toLocal().isAfter(now)) {
        all.putIfAbsent(event.id, () => event);
      }
    }
    final ordered = all.values.toList()
      ..sort((a, b) {
        final byDate = a.startDate.compareTo(b.startDate);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    if (ordered.isEmpty) {
      return const HomeSections(featured: null, sections: []);
    }
    final featured = ordered.first;
    final used = <String>{featured.id};
    final sections = <HomeSection>[];
    List<EventSummary> take(bool Function(EventSummary) matches) {
      final result = ordered
          .where((e) => !used.contains(e.id) && matches(e))
          .take(2)
          .toList();
      used.addAll(result.map((e) => e.id));
      return List.unmodifiable(result);
    }

    void add(
      String id,
      String title,
      List<EventSummary> items,
      String action, {
      EventDiscoveryFilter filter = const EventDiscoveryFilter(),
      bool favorites = false,
    }) {
      if (items.isNotEmpty) {
        sections.add(
          HomeSection(
            id: id,
            title: title,
            events: items,
            actionLabel: action,
            filter: filter,
            favorites: favorites,
          ),
        );
      }
    }

    if (ordered.length <= 3) {
      add(
        'more',
        'Mais experiências',
        take((_) => true),
        'Continuar em Explorar',
      );
      return HomeSections(
        featured: featured,
        sections: List.unmodifiable(sections),
      );
    }
    final savedIds = saved.map((e) => e.id).toSet();
    add(
      'saved',
      'Continue planejando',
      take((e) => savedIds.contains(e.id)),
      'Ver favoritos',
      favorites: true,
    );
    final weekend = EventDiscoveryFilter.weekend(now);
    add(
      'weekend',
      'Neste fim de semana',
      take(weekend.matches),
      'Explorar o fim de semana',
      filter: weekend,
    );
    final online = take((e) => e.locationType == 'online');
    var categories = 0;
    final categoriesInOrder = [
      for (final value in homeInterests)
        EventCatalog.categories.firstWhere((c) => c.value == value),
      ...EventCatalog.categories.where((c) => !homeInterests.contains(c.value)),
    ];
    for (final category in categoriesInOrder) {
      if (!ordered.any(
        (e) => !used.contains(e.id) && e.category == category.value,
      )) {
        continue;
      }
      add(
        'category-${category.value}',
        category.label,
        take((e) => e.category == category.value),
        'Explorar ${category.label.toLowerCase()}',
        filter: EventDiscoveryFilter(category: category.value),
      );
      if (++categories == 2) break;
    }
    add(
      'online',
      'De onde você estiver',
      online,
      'Explorar eventos online',
      filter: const EventDiscoveryFilter(locationType: 'online'),
    );
    if (sections.length < 6) {
      add(
        'more',
        'Mais experiências',
        take((_) => true),
        'Continuar em Explorar',
      );
    }
    return HomeSections(
      featured: featured,
      sections: List.unmodifiable(sections),
    );
  }
}
