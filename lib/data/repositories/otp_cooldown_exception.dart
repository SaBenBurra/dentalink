/// OTP gönderimi cooldown / rate-limit nedeniyle engellendiğinde fırlatılır.
///
/// [sameDestination] true ise aynı e-posta/telefona zaten kod gönderilmiş
/// demektir — yeni SMS atılmaz, kullanıcı OTP ekranına alınabilir.
/// false ise farklı bir hedefe çok sık deneme yapılmıştır — engellenir.
class OtpCooldownException implements Exception {
  const OtpCooldownException({
    required this.remainingSeconds,
    required this.sameDestination,
  });

  final int remainingSeconds;
  final bool sameDestination;

  @override
  String toString() =>
      'OtpCooldownException(remaining: ${remainingSeconds}s, same: $sameDestination)';
}
