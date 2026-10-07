import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Flutter's .first/.last throw when a lazy or transitioning control is absent.
Finder liveFirst(Finder target) => _LiveEdgeFinder(target, selectLast: false);
Finder liveLast(Finder target) => _LiveEdgeFinder(target, selectLast: true);

class _LiveEdgeFinder extends ChainedFinder {
  _LiveEdgeFinder(super.parent, {required this.selectLast});
  final bool selectLast;

  @override
  String get description =>
      '${parent.describeMatch(Plurality.many)} (${selectLast ? 'last' : 'first'})';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) => selectLast
      ? parentCandidates.toList().reversed.take(1)
      : parentCandidates.take(1);
}

/// Selects the vertical list in a page or panel, excluding horizontal chips.
Finder liveScrollable(Type scope) => find.descendant(
  of: find.byType(scope),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
  ),
);

Future<void> waitForLiveControl(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (target.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target, findsWidgets, reason: 'O controle esperado não apareceu.');
}

/// A mounted widget can be offscreen; lazy list children may not exist yet.
Future<void> revealLiveControl(
  WidgetTester tester,
  Finder target, {
  Finder? scrollable,
}) async {
  if (scrollable != null) {
    await waitForLiveControl(tester, scrollable);
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: scrollable,
      maxScrolls: 80,
    );
  } else {
    await waitForLiveControl(tester, target);
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'O controle deve estar visível e receber o toque.',
  );
}

Future<void> tapLive(
  WidgetTester tester,
  Finder target, {
  Finder? scrollable,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await revealLiveControl(tester, target, scrollable: scrollable);
  await tester.tap(target.hitTestable());
}

Future<void> enterLiveText(
  WidgetTester tester,
  Finder field,
  String value,
) async {
  await revealLiveControl(tester, field);
  await tester.enterText(field, value);
  await tester.pump();
  final editable = tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
  expect(
    editable.controller.text,
    value,
    reason: 'O campo deve receber o texto antes da próxima ação.',
  );
}
