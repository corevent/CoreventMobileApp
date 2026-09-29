import 'package:corevent_mobile_app/features/auth/presentation/document_formatter.dart';
import 'package:corevent_mobile_app/features/auth/presentation/verification_code_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('documento formata CPF e CNPJ preservando o cursor', () {
    final cpf = DocumentFormatter(isCompany: false);
    final cnpj = DocumentFormatter(isCompany: true);
    expect(cpf.formatDigits('52998224725'), '529.982.247-25');
    expect(cnpj.formatDigits('04252011000110'), '04.252.011/0001-10');

    final pasted = cpf.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '52998224725',
        selection: TextSelection.collapsed(offset: 11),
      ),
    );
    expect(pasted.text, '529.982.247-25');
    expect(pasted.selection.baseOffset, pasted.text.length);

    final edited = cpf.formatEditUpdate(
      pasted,
      const TextEditingValue(
        text: '529.982.247-2',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    expect(edited.selection.baseOffset, 4);
  });

  testWidgets('código aceita colagem de seis dígitos em um campo', (
    tester,
  ) async {
    var code = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => VerificationCodeField(
              code: code,
              onChanged: (value) => setState(() => code = value),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(code, '123456');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });
}
