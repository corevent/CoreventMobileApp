import '../data/event_dtos.dart';
import 'event_catalog.dart';

class EventDiscoveryFilter {
  const EventDiscoveryFilter({
    this.category,
    this.locationType,
    this.from,
    this.until,
  });
  final String? category;
  final String? locationType;
  final DateTime? from;
  final DateTime? until;
  bool get isEmpty =>
      category == null && locationType == null && from == null && until == null;
  bool matches(EventSummary event) =>
      (category == null || event.category == category) &&
      (locationType == null || event.locationType == locationType) &&
      (from == null || event.endDate.toLocal().isAfter(from!)) &&
      (until == null || event.startDate.toLocal().isBefore(until!));
  Map<String, String> get query => {
    'category': ?category,
    'mode': ?locationType,
    'from': ?from?.toIso8601String(),
    'until': ?until?.toIso8601String(),
  };
  factory EventDiscoveryFilter.fromQuery(Map<String, String> query) {
    final from = DateTime.tryParse(query['from'] ?? '')?.toLocal();
    final until = DateTime.tryParse(query['until'] ?? '')?.toLocal();
    final validRange = from == null || until == null || from.isBefore(until);
    final category = query['category'];
    return EventDiscoveryFilter(
      category: EventCatalog.categories.any((e) => e.value == category)
          ? category
          : null,
      locationType: query['mode'] == 'online' ? 'online' : null,
      from: validRange ? from : null,
      until: validRange ? until : null,
    );
  }
  factory EventDiscoveryFilter.weekend(DateTime now) {
    final local = now.toLocal();
    final friday = DateTime(
      local.year,
      local.month,
      local.day + DateTime.friday - local.weekday,
    );
    return EventDiscoveryFilter(
      from: friday,
      until: DateTime(friday.year, friday.month, friday.day + 3),
    );
  }
  @override
  bool operator ==(Object other) =>
      other is EventDiscoveryFilter &&
      category == other.category &&
      locationType == other.locationType &&
      from == other.from &&
      until == other.until;
  @override
  int get hashCode => Object.hash(category, locationType, from, until);
}
