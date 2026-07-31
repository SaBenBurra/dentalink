/// Sayıyı kısa biçimde formatlar.
///
/// 1000+ değerler "K" son eki ile gösterilir:
/// - 999 → "999"
/// - 1000 → "1K"
/// - 1200 → "1.2K"
/// - 1000000 → "1M"
String formatCount(int count) {
  if (count >= 1000000) {
    final value = count / 1000000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M';
  }
  if (count >= 1000) {
    final value = count / 1000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
  }
  return count.toString();
}
