/// The real API allows 10 login requests per minute. Keep each scenario's
/// independent UI login, including the deliberate invalid-password attempt.
class LiveLoginPacer {
  LiveLoginPacer({
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  static const minimumInterval = Duration(seconds: 7);
  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;
  DateTime? _lastAttempt;

  Future<void> beforeSubmit() async {
    final previous = _lastAttempt;
    if (previous != null) {
      final remaining = minimumInterval - _now().difference(previous);
      if (remaining > Duration.zero) await _wait(remaining);
    }
    _lastAttempt = _now();
  }
}
