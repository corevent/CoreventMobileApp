import 'package:corevent_mobile_app/features/auth/domain/auth_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CPF aceita máscara e rejeita dígitos inválidos', () {
    expect(validCpf('529.982.247-25'), isTrue);
    expect(validCpf('52998224724'), isFalse);
    expect(validCpf('111.111.111-11'), isFalse);
  });

  test('CNPJ aceita máscara e rejeita dígitos inválidos', () {
    expect(validCnpj('04.252.011/0001-10'), isTrue);
    expect(validCnpj('04.252.011/0001-11'), isFalse);
    expect(validCnpj('00.000.000/0000-00'), isFalse);
  });

  test('senha exige variedade de caracteres e código exige seis dígitos', () {
    expect(validPassword('Forte@123'), isTrue);
    expect(validPassword('fraca123'), isFalse);
    expect(validPassword('SEM_SIMBOLO1'), isFalse);
    expect(validPassword('Senha123'), isFalse);
    expect(validCode('123456'), isTrue);
    expect(validCode('12345'), isFalse);
    expect(validCode('12345a'), isFalse);
  });
}
