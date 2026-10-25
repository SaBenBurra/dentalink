/// Keyset sayfalama: liste `(created_at, id)` ile sıralıdır (çoğunlukla
/// en yeni önce); sonraki sayfa imleçten sonraki satırlardır. Ortaya eklenen ya
/// da silinen satırlar offset'teki gibi kaymaya yol açmaz (AUDIT DATA-12).
typedef PageCursor = ({DateTime createdAt, String id});

/// Bir sayfa ve sonrakinin imleci; [next] null ise başka sayfa yok.
typedef PageResult<T> = ({List<T> items, PageCursor? next});

const pageSize = 20;

/// Bir notifier'ın sayfalama durumu: imleç ve süren "daha fazla" isteği.
class Pager<T> {
  PageCursor? _next;
  Future<void>? _inFlight;
  int _generation = 0;

  bool get hasMore => _next != null;

  /// Süren [loadMore] sonucunu geçersiz kılar (yenileme, yeni arama).
  void reset() {
    _generation++;
    _inFlight = null;
    _next = null;
  }

  /// İlk sayfayı kaydeder ve öğelerini döner.
  List<T> first(PageResult<T> page) {
    reset();
    _next = page.next;
    return page.items;
  }

  /// Sonraki sayfayı çekip [append]'e verir. Aynı anda gelen çağrılar aynı
  /// isteği bekler; arada [reset] olduysa sonuç atılır. Hata fırlatılır.
  Future<void> loadMore(
    Future<PageResult<T>> Function(PageCursor cursor) fetch,
    void Function(List<T> items) append,
  ) {
    final cursor = _next;
    if (cursor == null) return Future.value();
    return _inFlight ??= _load(cursor, fetch, append);
  }

  Future<void> _load(
    PageCursor cursor,
    Future<PageResult<T>> Function(PageCursor cursor) fetch,
    void Function(List<T> items) append,
  ) async {
    final generation = _generation;
    try {
      final page = await fetch(cursor);
      if (generation != _generation) return;
      _next = page.next;
      append(page.items);
    } finally {
      if (generation == _generation) _inFlight = null;
    }
  }
}
