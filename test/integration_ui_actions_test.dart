import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/ui_actions.dart';

void main() {
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
