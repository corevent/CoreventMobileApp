import 'dart:async';

import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSession extends Mock implements AuthSession {}

void main() {
  late MockSession session;
  late ProviderContainer container;

  setUp(() {
    session = MockSession();
    container = ProviderContainer(
      overrides: [authSessionProvider.overrideWithValue(session)],
    );
  });
  tearDown(() => container.dispose());

  test('bloqueia atualizações simultâneas e exibe erro recuperável', () async {
    final pending = Completer<void>();
    when(() => session.refreshProfile()).thenAnswer((_) => pending.future);
    final model = container.read(profileViewModelProvider.notifier);
    final first = model.refresh();
    expect(container.read(profileViewModelProvider).busy, true);
    await model.refresh();
    verify(() => session.refreshProfile()).called(1);
    pending.completeError(Exception('offline'));
    await first;
    expect(container.read(profileViewModelProvider).busy, false);
    expect(container.read(profileViewModelProvider).error, isNotNull);
  });
}
