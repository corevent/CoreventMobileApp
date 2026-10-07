import 'package:corevent_mobile_app/app/app.dart';
import 'package:corevent_mobile_app/core/network/network_providers.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/auth/presentation/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'live_login_pacer.dart';
import 'live_ui_actions.dart';

export 'live_ui_actions.dart';

const _configuredUrl = String.fromEnvironment('COREVENT_API_URL');
const e2eEmail = String.fromEnvironment('COREVENT_E2E_EMAIL');
const e2ePassword = String.fromEnvironment('COREVENT_E2E_PASSWORD');
const e2eEventId = String.fromEnvironment('COREVENT_E2E_EVENT_ID');
const e2eFreeTicketName = String.fromEnvironment(
  'COREVENT_E2E_FREE_TICKET_NAME',
);

const _storage = FlutterSecureStorage();
final _loginPacer = LiveLoginPacer();

void validateLiveConfiguration({
  bool needsEvent = false,
  bool needsFreeTicket = false,
}) {
  final uri = Uri.tryParse(_configuredUrl);
  if (uri == null ||
      uri.host.isEmpty ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      apiBaseUrl != _configuredUrl) {
    throw StateError(
      'Informe --dart-define=COREVENT_API_URL com uma URL HTTP(S) válida.',
    );
  }
  if (e2eEmail.trim().isEmpty || e2ePassword.isEmpty) {
    throw StateError(
      'Informe COREVENT_E2E_EMAIL e COREVENT_E2E_PASSWORD por --dart-define.',
    );
  }
  if (needsEvent && e2eEventId.trim().isEmpty) {
    throw StateError(
      'Informe COREVENT_E2E_EVENT_ID retornado pelo preparador da API.',
    );
  }
  if (needsFreeTicket && e2eFreeTicketName.trim().isEmpty) {
    throw StateError(
      'Informe COREVENT_E2E_FREE_TICKET_NAME retornado pelo preparador da API.',
    );
  }
}

Future<void> clearLiveSession() async {
  await _storage.delete(key: TokenStore.accessKey);
  await _storage.delete(key: TokenStore.refreshKey);
}

Future<ProviderContainer> openLiveApp(
  WidgetTester tester, {
  ProviderContainer? providedContainer,
}) async {
  validateLiveConfiguration();
  // enterText injects editing events; a live IME can overwrite those values.
  tester.testTextInput.register();
  final container = providedContainer ?? ProviderContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CoreventApp()),
  );
  await pumpUntil(
    tester,
    () => container.read(authSessionProvider).status != SessionStatus.loading,
  );
  return container;
}

Future<void> closeLiveApp(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  tester.testTextInput.unregister();
}

Future<void> waitForLiveLogin(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final session = container.read(authSessionProvider);
  final login = container.read(loginViewModelProvider);
  await pumpUntil(
    tester,
    () =>
        session.status == SessionStatus.authenticated ||
        !login.busy && login.error != null,
  );
  expect(
    session.status,
    SessionStatus.authenticated,
    reason: login.error ?? 'A conta de E2E não conseguiu entrar na API real.',
  );
  // Keep image error handlers mounted until pending Home images have resolved.
  // Otherwise navigating away can leave only the image cache listening.
  await pumpUntil(
    tester,
    () => PaintingBinding.instance.imageCache.pendingImageCount == 0,
  );
}

Future<void> loginLive(WidgetTester tester, ProviderContainer container) async {
  final session = container.read(authSessionProvider);
  if (session.status == SessionStatus.authenticated) return;
  expect(session.status, SessionStatus.unauthenticated);
  await openLiveLogin(tester);
  final fields = find.byType(TextField);
  await enterLiveText(tester, fields.at(0), e2eEmail);
  await enterLiveText(tester, fields.at(1), e2ePassword);
  await submitLiveLogin(tester);
  await waitForLiveLogin(tester, container);
}

Future<void> openLiveLogin(WidgetTester tester) async {
  await tapLive(tester, find.text('Já tenho uma conta'));
  await waitForLiveControl(tester, find.text('Bem-vindo de volta!'));
  await waitForLiveControl(tester, find.byType(TextField));
  expect(find.byType(TextField), findsNWidgets(2));
}

Future<void> submitLiveLogin(WidgetTester tester) async {
  await _loginPacer.beforeSubmit();
  await tapLive(tester, find.text('Entrar'));
}

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (!condition()) throw TestFailure('Tempo esgotado aguardando a API real.');
  await tester.pumpAndSettle();
}
