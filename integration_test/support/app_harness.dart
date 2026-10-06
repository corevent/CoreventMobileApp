import 'package:corevent_mobile_app/app/app.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_backend.dart';

const fixtureStorage = FlutterSecureStorage();

Future<void> clearFixtureSession() async {
  await fixtureStorage.delete(key: TokenStore.accessKey);
  await fixtureStorage.delete(key: TokenStore.refreshKey);
}

Future<void> seedSession() async {
  await fixtureStorage.write(
    key: TokenStore.accessKey,
    value: FixtureBackend.accessToken,
  );
  await fixtureStorage.write(
    key: TokenStore.refreshKey,
    value: FixtureBackend.refreshToken,
  );
}

Future<ProviderContainer> openApp(
  WidgetTester tester,
  FixtureBackend backend,
) async {
  // Keep the native IME from overwriting text injected by WidgetTester.
  tester.testTextInput.register();
  final container = backend.createContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CoreventApp()),
  );
  final session = container.read(authSessionProvider);
  for (
    var attempt = 0;
    attempt < 50 && session.status == SessionStatus.loading;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(session.status, isNot(SessionStatus.loading));
  await tester.pumpAndSettle();
  return container;
}

Future<void> closeApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  tester.testTextInput.unregister();
}
