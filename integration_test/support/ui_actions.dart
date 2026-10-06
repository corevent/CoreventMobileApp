import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls mounted controls away from fixed footers before touching them.
Future<void> tapFixture(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
}

Future<void> enterFixtureText(
  WidgetTester tester,
  Finder field,
  String value, {
  String? expectedText,
}) async {
  await Scrollable.ensureVisible(tester.element(field), alignment: .5);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pump();
  final editable = tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
  expect(editable.controller.text, expectedText ?? value);
}
