/// Kullanıcı adını ad soyaddan türetir.
///
/// Türkçe karakterleri ASCII'ye normalize eder ve benzersizlik
/// için zaman damgası suffix'i ekler.
///
/// Örnek: "Ahmet Yılmaz" → "ahmet_yilmaz_1234"
String generateUsername(String fullName) {
  final base = fullName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_');

  // Türkçe karakterleri normalize et
  const turkishMap = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
  };
  var normalized = base;
  turkishMap.forEach((tr, en) {
    normalized = normalized.replaceAll(tr, en);
  });

  if (normalized.isEmpty) normalized = 'user';

  final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
  return '${normalized}_$suffix';
}
