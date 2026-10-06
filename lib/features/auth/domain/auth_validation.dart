String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

bool validEmail(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());

class PasswordChecks {
  const PasswordChecks(
    this.length,
    this.uppercase,
    this.lowercase,
    this.number,
    this.symbol,
  );
  final bool length;
  final bool uppercase;
  final bool lowercase;
  final bool number;
  final bool symbol;

  bool get complete => length && uppercase && lowercase && number && symbol;
}

PasswordChecks checkPassword(String password) => PasswordChecks(
  password.length >= 8,
  RegExp(r'[A-Z]').hasMatch(password),
  RegExp(r'[a-z]').hasMatch(password),
  RegExp(r'[0-9]').hasMatch(password),
  RegExp(r'[^A-Za-z0-9]').hasMatch(password),
);

bool validPassword(String password) => checkPassword(password).complete;

bool validCode(String code) => RegExp(r'^\d{6}$').hasMatch(code);

bool validCpf(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 11 || RegExp(r'^(\d)\1+$').hasMatch(digits)) {
    return false;
  }
  final nums = digits.split('').map(int.parse).toList();
  for (var check = 9; check <= 10; check++) {
    var sum = 0;
    for (var i = 0; i < check; i++) {
      sum += nums[i] * (check + 1 - i);
    }
    final remainder = sum % 11;
    final expected = remainder < 2 ? 0 : 11 - remainder;
    if (nums[check] != expected) return false;
  }
  return true;
}

bool validCnpj(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 14 || RegExp(r'^(\d)\1+$').hasMatch(digits)) {
    return false;
  }
  final nums = digits.split('').map(int.parse).toList();
  const weights = [
    [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
    [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
  ];
  for (var check = 12; check <= 13; check++) {
    var sum = 0;
    for (var i = 0; i < check; i++) {
      sum += nums[i] * weights[check - 12][i];
    }
    final remainder = sum % 11;
    final expected = remainder < 2 ? 0 : 11 - remainder;
    if (nums[check] != expected) return false;
  }
  return true;
}
