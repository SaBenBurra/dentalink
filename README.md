# DentLink

Diş hekimleri ve öğrenciler için mobil sosyal platform (Flutter + Supabase).

| Doküman | İçerik |
|---|---|
| [`agents.md`](agents.md) | Ürün kapsamı, mimari, **kodlama kuralları** |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Fazlar ve sıradaki iş |
| [`docs/AUDIT.md`](docs/AUDIT.md) | Bilinen bug ve eksikler (ID'li) |
| [`docs/SUPABASE.md`](docs/SUPABASE.md) | Migration akışı, RLS kuralları, smoke testleri |

## Gereksinimler

- Flutter 3.47.x (Dart ^3.12)
- Supabase CLI (yalnızca migration için)
- Android Studio ve/veya Xcode (cihaz/emülatör)

## Kurulum

```bash
flutter pub get
flutter gen-l10n          # lib/core/l10n/generated/ (ARB değişince tekrar çalıştır)
flutter run
```

Supabase URL ve anon key şu an `lib/main.dart` içinde. Faz 5'te `--dart-define-from-file` ile ortam bazlı hale gelecek.

## Supabase

```bash
supabase link --project-ref lknvufbxekceevdblgmq   # SUPABASE_ACCESS_TOKEN ve SUPABASE_DB_PASSWORD gerekir
                                                   # şifre: supabase/.env.local içine SUPABASE_DB_PASSWORD=… (gitignored, CLI otomatik okur)
supabase migration list                            # local == remote olmalı
supabase migration new <ad>                        # yeni şema değişikliği
supabase db push --dry-run && supabase db push
```

Ayrıntılar ve kurallar: [`docs/SUPABASE.md`](docs/SUPABASE.md).

## Test & kalite

```bash
flutter analyze
flutter test                                       # unit testler + headless uçtan uca akış (CI da bunu koşar)
dart run build_runner build -d                     # test/mocks/*.mocks.dart yeniden üret
flutter test integration_test                      # cihaz/emülatör gerekir
```

## Klasör haritası

```
lib/core       tema, router, l10n, hata tipleri
lib/data       modeller, repository'ler (Supabase), DI
lib/providers  global Riverpod state
lib/features   ekranlar (auth, feed, post, profile, search, messaging, notifications, bookmarks, settings)
lib/shared     ortak widget'lar ve extension'lar
supabase/      config.toml + migrations/
test/          unit testler (mockito)
```
