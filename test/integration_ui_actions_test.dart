import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/ui_actions.dart';

void main() {
  testWidgets('waits for async UI updates after scheduled frames settle', (
    tester,
  ) async {
    var complete = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) => GestureDetector(
            onTap: () async {
              await Future<void>.delayed(const Duration(milliseconds: 800));
              setState(() => complete = true);
            },
            child: Text(complete ? 'Destino' : 'Entrar'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Destino'), findsNothing);
    await waitForFixtureText(tester, 'Destino');
    expect(find.text('Destino'), findsOneWidget);
  });

  testWidgets('scrolls to a logout action not yet built by a lazy list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: const SizedBox(height: 80),
          body: ListView.builder(
            itemCount: 20,
            itemBuilder: (_, index) => index == 19
                ? TextButton(
                    onPressed: () => tapped = true,
                    child: const Text('Sair da conta'),
                  )
                : const SizedBox(height: 100),
          ),
        ),
      ),
    );
    expect(find.text('Sair da conta'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Sair da conta'),
      160,
      scrollable: find.byType(Scrollable),
    );
    await tapFixture(tester, find.text('Sair da conta'));
    expect(tapped, isTrue);
  });

  testWidgets(
    'scrolls an offscreen action above a fixed footer before tapping',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: const SizedBox(height: 80),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 740),
                  TextButton(
                    onPressed: () => tapped = true,
                    child: const Text('Continuar'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Continuar').hitTestable(), findsNothing);
      await tapFixture(tester, find.text('Continuar'));
      expect(tapped, isTrue);
    },
  );
}
