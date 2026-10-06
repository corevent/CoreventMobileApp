import '../data/auth_dtos.dart';
import 'auth_validation.dart';

class RegistrationDraft {
  String name = '';
  DateTime? birthDate;
  String? accountType;
  String document = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  RegisterRequest toRequest(String code) => RegisterRequest(
    name: name.trim(),
    // Kept for compatibility with the current MAUI client contract.
    phoneNumber: '14981234567',
    avatarUrl: 'https://placehold.co/300x300/jpg',
    email: email.trim(),
    password: password,
    birthDate:
        '${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
    documentType: accountType == 'pj' ? 'cnpj' : 'cpf',
    document: onlyDigits(document),
    verifyEmailCode: code,
  );
}
