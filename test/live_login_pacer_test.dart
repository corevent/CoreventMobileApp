import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e/support/live_login_pacer.dart';

void main() {
  late DateTime now;
  late List<Duration> waits;
  late LiveLoginPacer pacer;

  setUp(() {
    now = DateTime.utc(2026, 10, 7);
    waits = [];
    pacer = LiveLoginPacer(
      now: () => now,
      wait: (duration) async {
        waits.add(duration);
        now = now.add(duration);
      },
    );
  });

  test('first login does not wait', () async {
    await pacer.beforeSubmit();
    expect(waits, isEmpty);
  });

  test('waits only the remaining interval before the next attempt', () async {
    await pacer.beforeSubmit();
    now = now.add(const Duration(seconds: 5));
    await pacer.beforeSubmit();
    expect(waits, [const Duration(seconds: 2)]);
  });

  test('a scenario that already took seven seconds does not wait', () async {
    await pacer.beforeSubmit();
    now = now.add(LiveLoginPacer.minimumInterval);
    await pacer.beforeSubmit();
    expect(waits, isEmpty);
  });

  test(
    'a burst including failed attempts stays under ten logins per minute',
    () async {
      final attempts = <DateTime>[];
      for (var attempt = 0; attempt < 12; attempt++) {
        await pacer.beforeSubmit();
        attempts.add(now);
      }
      for (final start in attempts) {
        final inWindow = attempts.where(
          (time) =>
              !time.isBefore(start) &&
              time.difference(start) < const Duration(minutes: 1),
        );
        expect(inWindow.length, lessThanOrEqualTo(10));
      }
    },
  );
}
