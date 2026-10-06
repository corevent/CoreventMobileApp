import 'dart:async';

import 'package:corevent_mobile_app/app/router.dart';
import 'package:corevent_mobile_app/core/design_system/corevent_button.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_forms_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/app_harness.dart';
import '../support/fixture_backend.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
  setUp(clearFixtureSession);
  tearDown(clearFixtureSession);

  testWidgets('edita dados pessoais e altera senha', (tester) async {
    await seedSession();
    final backend = FixtureBackend();
    final container = await openApp(tester, backend);

    unawaited(container.read(routerProvider).push('/profile/details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ana Integração');
    await tester.pumpAndSettle();
    final draft = container.read(detailsViewModelProvider);
    expect(draft.name, 'Ana Integração');
    expect(draft.dirty, isTrue);
    expect(draft.valid, isTrue);
    expect(
      tester
          .widget<CoreventButton>(
            find.widgetWithText(CoreventButton, 'Salvar alterações'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(backend.updateProfileCalls, 1);
    expect(backend.profileName, 'Ana Integração');
    expect(find.text('Dados atualizados.'), findsOneWidget);

    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    unawaited(container.read(routerProvider).push('/profile/security'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'SenhaAntiga1!');
    await tester.enterText(find.byType(TextField).at(1), 'NovaSenha123!');
    await tester.enterText(find.byType(TextField).at(2), 'NovaSenha123!');
    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();
    expect(backend.changePasswordCalls, 1);
    backend.expectOnlySupportedRequests();
    await closeApp(tester, container);
  });
}
