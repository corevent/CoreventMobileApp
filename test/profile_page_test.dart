import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSession extends Mock implements AuthSession {}

void main() {
  testWidgets('cabeçalho permanece visível com fonte ampliada e rolagem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = MockSession();
    when(() => session.user).thenReturn(
      UserProfile(
        id: 'u1',
        name: 'Ana Silva',
        email: 'ana@exemplo.com',
        createdAt: DateTime(2026, 9, 20),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionProvider.overrideWithValue(session)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: const Scaffold(body: ProfilePage()),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Ana Silva'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
