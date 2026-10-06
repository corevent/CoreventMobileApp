import '../data/event_dtos.dart';

bool isAdult(String? birthDate, DateTime now) {
  final birth = birthDate == null ? null : DateTime.tryParse(birthDate);
  if (birth == null || birth.isAfter(now)) return false;
  var age = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age >= 18;
}

List<EventSummary> visibleEvents(
  Iterable<EventSummary> events, {
  required String? birthDate,
  required DateTime now,
}) {
  final adult = isAdult(birthDate, now);
  final unique = <String, EventSummary>{};
  for (final event in events) {
    if (!event.endDate.toLocal().isAfter(now) ||
        (event.isAdultOnly && !adult)) {
      continue;
    }
    unique.putIfAbsent(event.id, () => event);
  }
  final result = unique.values.toList();
  result.sort((a, b) => a.startDate.compareTo(b.startDate));
  return result;
}
