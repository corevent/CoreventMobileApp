import 'package:corevent_mobile_app/features/auth/presentation/birth_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('nascimento aceita ano direto e rejeita datas impossíveis', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirthDateField(
            initialDate: null,
            onChanged: (date) => selected = date,
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(3));
    await tester.enterText(find.byType(TextField).at(0), '31');
    await tester.enterText(find.byType(TextField).at(1), '02');
    await tester.enterText(find.byType(TextField).at(2), '1980');
    expect(selected, isNull);

    await tester.enterText(find.byType(TextField).at(0), '29');
    await tester.enterText(find.byType(TextField).at(1), '02');
    await tester.enterText(find.byType(TextField).at(2), '2000');
    expect(selected, DateTime(2000, 2, 29));
  });

  testWidgets('nascimento aceita data completa colada no primeiro campo', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirthDateField(
            initialDate: null,
            onChanged: (date) => selected = date,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '12/06/1998');
    await tester.pump();
    expect(selected, DateTime(1998, 6, 12));
    expect(find.text('1998'), findsOneWidget);
  });
}
