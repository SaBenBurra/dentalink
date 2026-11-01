import 'dart:math';

final _random = Random();

/// Kullanıcı adını ad soyaddan türetir.
///
/// Türkçe karakterleri ASCII'ye normalize eder ve benzersizlik
/// için rastgele bir suffix ekler.
///
/// Örnek: "Çağrı Şen" → "cagri_sen_123456"
String generateUsername(String fullName) {
  // Türkçe eşleme küçük harfe çevirmeden ve ASCII dışını silmeden ÖNCE yapılmalı;
  // aksi halde 'ç', 'İ' gibi harfler silinir ya da 'i̇' olur.
  const turkishMap = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
    'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'I': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u',
  };
  var normalized = fullName.trim();
  turkishMap.forEach((tr, en) {
    normalized = normalized.replaceAll(tr, en);
  });
  normalized = normalized
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');

  if (normalized.isEmpty) normalized = 'user';

  final suffix = _random.nextInt(900000) + 100000;
  return '${normalized}_$suffix';
}

/// Türkçe alfabetik karşılaştırma: Ç, Ğ, I, Ö, Ş, Ü kendi harflerinden sonra
/// gelir (kod noktası sırasında Z'nin arkasına düşerlerdi).
int compareTurkish(String a, String b) => _trSortKey(a).compareTo(_trSortKey(b));

String _trSortKey(String s) {
  // Harfin hemen ardına U+007F: "ce" < "c\x7f…" yani C'li sözcükler Ç'lilerden önce.
  const after = {
    'ç': 'c\x7f', 'ğ': 'g\x7f', 'ı': 'h\x7f', 'ö': 'o\x7f', 'ş': 's\x7f', 'ü': 'u\x7f',
  };
  final lower = s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  return lower.split('').map((c) => after[c] ?? c).join();
}
