final _emailRegex = RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,}$');
final _e164Regex = RegExp(r'^\+[1-9][0-9]{7,14}$');
final _trMobileRegex = RegExp(r'^(?:0|90)?(5[0-9]{9})$');
final _phoneSeparators = RegExp(r'[\s()\-.]');

/// Küçük harfli e-posta; geçersizse null.
String? normalizeEmail(String input) {
  final email = input.trim().toLowerCase();
  return _emailRegex.hasMatch(email) ? email : null;
}

/// E.164 telefon. Ülke kodu yazılmamışsa yalnızca Türkiye cep numarası kabul
/// edilir (5xx, 05xx, 905xx); geçersizse null.
String? normalizePhone(String input) {
  var phone = input.trim().replaceAll(_phoneSeparators, '');
  if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
  final tr = _trMobileRegex.firstMatch(phone);
  if (tr != null) return '+90${tr[1]}';
  return _e164Regex.hasMatch(phone) ? phone : null;
}

/// Giriş alanındaki değeri normalleştirir; e-posta da telefon da değilse null.
String? normalizeContact(String input) =>
    normalizeEmail(input) ?? normalizePhone(input);

bool isEmailContact(String contact) => contact.contains('@');
