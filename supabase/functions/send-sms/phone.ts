/** Türkiye cep numarasını +905xxxxxxxxx yapar, başka her şeyde null. Auth numarayı `+` olmadan yollar. */
export function turkishMobile(phone: unknown): string | null {
  return typeof phone === 'string' && /^\+?905\d{9}$/.test(phone) ? `+${phone.replace('+', '')}` : null;
}
