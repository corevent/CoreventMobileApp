import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/app_harness.dart';
import '../support/fixture_backend.dart';
import '../support/ui_actions.dart';

Future<void> _waitForText(WidgetTester tester, String value) async {
  for (
    var attempt = 0;
    attempt < 50 && find.text(value).evaluate().isEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.text(value), findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
  setUp(clearFixtureSession);
  tearDown(clearFixtureSession);

  testWidgets('login inválido permite corrigir e entrar', (tester) async {
    final backend = FixtureBackend()..failNextLogin = true;
    final container = await openApp(tester, backend);
    await tapFixture(tester, find.text('Já tenho uma conta'));
    await tester.pumpAndSettle();
    await enterFixtureText(
      tester,
      find.byType(TextField).at(0),
      'ana@integration.test',
    );
    await enterFixtureText(tester, find.byType(TextField).at(1), 'Senha1!');
    await tapFixture(tester, find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(await fixtureStorage.read(key: TokenStore.accessKey), isNull);
    await tapFixture(tester, find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Festival de integração'), findsWidgets);
    expect(backend.loginCalls, 2);
    backend.expectOnlySupportedRequests();
    await closeApp(tester, container);
  });

  testWidgets('recuperação verifica código e redefine senha', (tester) async {
    final backend = FixtureBackend();
    final container = await openApp(tester, backend);
    await tapFixture(tester, find.text('Já tenho uma conta'));
    await tester.pumpAndSettle();
    await tapFixture(tester, find.text('Esqueceu a senha?'));
    await tester.pumpAndSettle();
    await enterFixtureText(
      tester,
      find.byType(TextField).first,
      'ana@integration.test',
    );
    await tapFixture(tester, find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(backend.forgotPasswordCalls, 1);

    await tapFixture(tester, find.text('Verificar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Insira o código de 6 dígitos enviado por e-mail.'),
      findsOneWidget,
    );
    await enterFixtureText(tester, find.byType(TextField).last, '123456');
    await tapFixture(tester, find.text('Verificar'));
    await tester.pumpAndSettle();
    expect(find.text('Redefinir senha'), findsWidgets);
    await enterFixtureText(tester, find.byType(TextField).at(0), 'NovaSenha1!');
    await enterFixtureText(tester, find.byType(TextField).at(1), 'NovaSenha1!');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Redefinir senha').last);
    await tapFixture(tester, find.text('Redefinir senha').last);
    await _waitForText(tester, 'Bem-vindo de volta!');
    expect(backend.resetPasswordCalls, 1);
    expect(await fixtureStorage.read(key: TokenStore.accessKey), isNull);
    backend.expectOnlySupportedRequests();
    await closeApp(tester, container);
  });

  testWidgets('cadastro exige Próximo após selecionar pessoa física', (
    tester,
  ) async {
    final backend = FixtureBackend()..failNextRegister = true;
    final container = await openApp(tester, backend);
    await tapFixture(tester, find.text('Criar conta'));
    await tester.pumpAndSettle();
    await enterFixtureText(tester, find.byType(TextField).at(0), 'Ana Teste');
    await enterFixtureText(tester, find.byType(TextField).at(1), '01');
    await enterFixtureText(tester, find.byType(TextField).at(2), '01');
    await enterFixtureText(tester, find.byType(TextField).at(3), '2000');
    await tapFixture(tester, find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Pessoa ou empresa?'), findsOneWidget);
    await tapFixture(tester, find.text('Pessoa Física'));
    await tester.pumpAndSettle();
    expect(find.text('Pessoa ou empresa?'), findsOneWidget);
    await tapFixture(tester, find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Seu documento'), findsOneWidget);
    await enterFixtureText(
      tester,
      find.byType(TextField).last,
      '52998224725',
      expectedText: '529.982.247-25',
    );
    await tapFixture(tester, find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Credenciais de acesso'), findsOneWidget);
    await enterFixtureText(
      tester,
      find.byType(TextField).at(0),
      'ana@integration.test',
    );
    await enterFixtureText(tester, find.byType(TextField).at(1), 'Senha123!');
    await enterFixtureText(tester, find.byType(TextField).at(2), 'Senha123!');
    await tapFixture(tester, find.text('Finalizar'));
    await tester.pumpAndSettle();
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(backend.verifyEmailCalls, 1);
    await enterFixtureText(tester, find.byType(TextField).last, '123456');
    await tapFixture(tester, find.text('Verificar'));
    await tester.pumpAndSettle();
    expect(backend.registerCalls, 1);
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    await tapFixture(tester, find.text('Verificar'));
    await tester.pumpAndSettle();
    expect(backend.registerCalls, 2);
    expect(backend.loginCalls, 1);
    final registration =
        backend.requests
                .firstWhere((request) => request.path == '/api/auth/register')
                .data
            as Map<String, dynamic>;
    expect(registration['document'], '52998224725');
    expect(registration['birthDate'], '2000-01-01');
    expect(registration['verifyEmailCode'], '123456');
    await _waitForText(tester, 'Festival de integração');
    backend.expectOnlySupportedRequests();
    await closeApp(tester, container);
  });
}
