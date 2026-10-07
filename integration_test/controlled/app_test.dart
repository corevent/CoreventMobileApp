import 'package:corevent_mobile_app/app/router.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../support/app_harness.dart';
import '../support/fixture_backend.dart';
import '../support/ui_actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
  setUp(clearFixtureSession);
  tearDown(clearFixtureSession);

  testWidgets('login, abas, restauração do storage e logout', (tester) async {
    final backend = FixtureBackend();
    var container = await openApp(tester, backend);
    expect(find.text('Já tenho uma conta'), findsOneWidget);

    await tapFixture(tester, find.text('Já tenho uma conta'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await enterFixtureText(tester, fields.at(0), 'ana@integration.test');
    await enterFixtureText(tester, fields.at(1), 'Senha1!');
    await tapFixture(tester, find.text('Entrar'));
    await waitForFixtureText(tester, 'Festival de integração');
    expect(backend.loginCalls, 1);
    expect(
      container.read(authSessionProvider).status,
      SessionStatus.authenticated,
    );
    expect(
      await fixtureStorage.read(key: TokenStore.accessKey),
      FixtureBackend.accessToken,
    );

    await tapFixture(tester, find.text('Explorar').last);
    await waitForFixtureText(tester, 'Festival de integração');
    await tapFixture(tester, find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.text('Ana Teste'), findsOneWidget);

    await closeApp(tester, container);
    container = await openApp(tester, backend);
    await waitForFixtureText(tester, 'Festival de integração');
    expect(
      container.read(authSessionProvider).status,
      SessionStatus.authenticated,
    );

    await tapFixture(tester, find.text('Perfil').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sair da conta'),
      160,
      scrollable: find.descendant(
        of: find.byType(ProfilePage),
        matching: find.byType(Scrollable),
      ),
    );
    await tapFixture(tester, find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta?'), findsOneWidget);
    await tapFixture(tester, find.text('Sair').last);
    await waitForFixtureText(tester, 'Já tenho uma conta');
    expect(find.text('Já tenho uma conta'), findsOneWidget);
    expect(await fixtureStorage.read(key: TokenStore.accessKey), isNull);
    expect(await fixtureStorage.read(key: TokenStore.refreshKey), isNull);
    await closeApp(tester, container);
  });

  testWidgets('pedido pendente só libera QR após confirmação paga', (
    tester,
  ) async {
    await seedSession();
    final backend = FixtureBackend();
    final container = await openApp(tester, backend);
    expect(find.text('Festival de integração'), findsWidgets);
    container
        .read(routerProvider)
        .go('/events/${FixtureBackend.eventId}/checkout');
    await tester.pumpAndSettle();
    await tapFixture(tester, find.byTooltip('Adicionar Inteira'));
    await tester.pumpAndSettle();
    await tapFixture(tester, find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(backend.createOrderCalls, 1);
    expect(find.text('Aguardando pagamento'), findsOneWidget);
    expect(find.text('Ver meus ingressos'), findsNothing);

    backend.orderPaid = true;
    await tapFixture(tester, find.text('Atualizar status'));
    await tester.pumpAndSettle();
    expect(find.text('Pedido confirmado'), findsOneWidget);
    await tapFixture(tester, find.text('Ver meus ingressos'));
    await tester.pumpAndSettle();
    expect(find.text('Ver QR Code'), findsOneWidget);
    await tapFixture(tester, find.text('Ver QR Code'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    await closeApp(tester, container);
  });

  testWidgets('falha de rede na Home oferece nova tentativa', (tester) async {
    await seedSession();
    final backend = FixtureBackend()..failNextEvents = true;
    final container = await openApp(tester, backend);
    expect(find.text('Eventos indisponíveis'), findsOneWidget);
    await tapFixture(tester, find.text('Tentar novamente').first);
    await tester.pumpAndSettle();
    expect(find.text('Festival de integração'), findsWidgets);
    await closeApp(tester, container);
  });

  testWidgets('401 ao restaurar renova token e repete perfil uma vez', (
    tester,
  ) async {
    await seedSession();
    final backend = FixtureBackend()..failNextProfileUnauthorized = true;
    final container = await openApp(tester, backend);
    expect(
      container.read(authSessionProvider).status,
      SessionStatus.authenticated,
    );
    expect(find.text('Festival de integração'), findsWidgets);
    expect(backend.refreshCalls, 1);
    expect(
      backend.requests.where((request) => request.path == '/api/users/me'),
      hasLength(2),
    );
    backend.expectOnlySupportedRequests();
    await closeApp(tester, container);
  });

  testWidgets('refresh recusado encerra a sessão local', (tester) async {
    await seedSession();
    final backend = FixtureBackend()
      ..failNextProfileUnauthorized = true
      ..failRefresh = true;
    final container = await openApp(tester, backend);
    expect(
      container.read(authSessionProvider).status,
      SessionStatus.unauthenticated,
    );
    expect(find.text('Já tenho uma conta'), findsOneWidget);
    expect(backend.refreshCalls, 1);
    expect(await fixtureStorage.read(key: TokenStore.accessKey), isNull);
    expect(await fixtureStorage.read(key: TokenStore.refreshKey), isNull);
    backend.expectOnlySupportedRequests();
    await closeApp(tester, container);
  });
}
