import 'dart:async';

import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/profile/data/profile_repository.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remixicon/remixicon.dart';

class MockSession extends Mock implements AuthSession {}

class MockRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  const user = UserProfile(
    id: 'u1',
    name: 'Ana Silva',
    email: 'ana@example.com',
    phoneNumber: '+5511999999999',
    document: '52998224725',
    documentType: 'cpf',
    birthDate: '1990-01-12',
  );
  late MockSession session;
  late MockRepository repository;

  setUp(() {
    session = MockSession();
    repository = MockRepository();
    when(() => session.user).thenReturn(user);
  });

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWithValue(session),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: const ProfileDetailsPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scale in [1.5, 2.0]) {
    testWidgets('dados e edição acessíveis com fonte $scale e teclado', (
      tester,
    ) async {
      await open(tester, scale: scale);
      expect(find.byType(TextField), findsNothing);
      final scrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Editar'),
        150,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField).last,
        100,
        scrollable: scrollable,
      );
      await tester.enterText(find.byType(TextField).last, '11');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Informe o DDD e um telefone válido.'),
        100,
        scrollable: scrollable,
      );
      expect(find.text('Informe o DDD e um telefone válido.'), findsOneWidget);
      expect(find.text('Cancelar edição'), findsOneWidget);
      expect(
        tester.getRect(find.text('Cancelar edição')).bottom,
        lessThan(480),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancelar pede confirmação e preserva rascunho ao continuar', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ana Souza');
    await tester.tap(find.text('Cancelar edição'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Ana Souza',
    );
    await tester.tap(find.text('Cancelar edição'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('falha mantém edição e bloqueia interações durante envio', (
    tester,
  ) async {
    final response = Completer<UserProfile>();
    when(() => repository.updateFields(any()))
        .thenAnswer((_) => response.future);
    await open(tester);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ana Souza');
    await tester.pump();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      false,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, RemixIcons.arrow_left_line),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Cancelar edição'),
          )
          .onPressed,
      isNull,
    );
    response.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível salvar seus dados.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Ana Souza',
    );
  });
}
