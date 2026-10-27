# DentLink — Proje Rehberi (insanlar ve AI ajanları için)

> Diş hekimleri ve diş hekimliği öğrencileri için mobil sosyal platform: vaka paylaşımı, soru-cevap forumu, takip, DM ve bildirimler. "Diş hekimliğine özel LinkedIn."

**Önce şunları oku:**
- [`docs/ROADMAP.md`](docs/ROADMAP.md): ne yapılıyor, sıradaki iş ne. **İlk açık fazdan devam et.**
- [`docs/AUDIT.md`](docs/AUDIT.md): bilinen bütün bug ve eksikler (ID'li). Bir maddeyi çözünce durumunu güncelle.
- [`docs/SUPABASE.md`](docs/SUPABASE.md): migration akışı, RLS/GRANT kuralları, smoke testleri.
- [`README.md`](README.md): kurulum ve komutlar.

---

## Teknoloji

| | |
|---|---|
| Platform | Flutter 3.47 (Dart SDK ^3.12), Android + iOS |
| Backend | Supabase: Auth (e-posta/SMS OTP), Postgres + RLS, Storage, Realtime |
| State | `flutter_riverpod` 2.x (elle yazılmış provider'lar, codegen yok) |
| Navigasyon | `go_router` (auth guard redirect + `ShellRoute` alt menü) |
| Dil | TR (şablon) + EN, ARB → `lib/core/l10n/generated` |
| Tasarım | Material 3 + glassmorphism (`GlassThemeExtension`), Teal/Mint paleti, Plus Jakarta Sans |

---

## Mimari

```
lib/
  core/        tema, sabitler, router, l10n, hata tipleri (app_failures), supabase_error_mapper
  data/        modeller, repository arayüzleri + Supabase implementasyonları, repository_providers.dart (DI)
  providers/   birden fazla feature'ın kullandığı global state (auth, feed, post, comment, follow, message, search…)
  features/<x>/{screens,widgets,providers}   feature'a özel UI ve controller'lar
  shared/      ortak widget'lar, model→UI extension'ları, error_messages
```

- **Repository pattern:** abstract arayüz + `Supabase*Repository`. UI asla `Supabase.instance` çağırmaz; DI `lib/data/providers/repository_providers.dart` üzerinden yapılır.
- **Post tipleri:** `PostModel` sealed class (`CasePostModel`, `QuestionPostModel`), kart seçimi `PostCardFactory` ile. Yeni tip = yeni varyant + kart; feed ve arama genel kalır.
- **Model saflığı:** modellerde Material import'u yok. UI davranışı (renk, ikon, l10n) `lib/shared/extensions/` altında.

---

## Kodlama kuralları (zorunlu)

1. **Şema değişikliği yalnızca yeni migration ile** yapılır (`docs/SUPABASE.md`). Dashboard'dan elle SQL yok.
2. **Repository metotları** `guardSupabase` (`lib/core/utils/supabase_error_mapper.dart`) ile sarılır ve `AppFailure` fırlatır.
3. **Kullanıcıya ham hata gösterme.** `getErrorMessage(e)` (`lib/shared/utils/error_messages.dart`) kullan. `Text('Hata: $e')` yasak.
4. **"Bulunamadı" ile "hata" ayrı şeylerdir.** `catch (_) { return null; }` yazma. Null yalnızca kayıt gerçekten yoksa dönülür.
5. **Mutasyondan sonra etkilenen provider'ları güncelle.** Post oluştur/sil → `feedProvider`, `userPostsProvider(uid)`, `authProvider`. Mümkünse tüm listeyi yeniden çekme, tek öğeyi güncelle.
6. **İyimser güncelleme = in-flight guard + rollback.** Örnek kalıp: `lib/providers/comment_provider.dart` (`_pending…`).
7. **Kullanıcıya özel state çıkışta temizlenir.** Kullanıcı verisi tutan her provider ya `authProvider`'dan user id'yi `watch` eder ya da `signOut` içinde invalidate edilir.
8. **`copyWith`'te nullable alan** için `T? Function()?` (ValueGetter) kalıbını kullan; `??` ile null'a geri dönülemez.
9. **`await` sonrası** `if (!mounted) return;` (widget) veya `ref.mounted` (notifier) kontrolü yap.
10. **Metinler ARB'den gelir** (`AppLocalizations.of(context)`). Yeni ekranda sabit metin yazma; TR ve EN'e birlikte ekle.
11. **Renkler ve ölçüler temadan gelir:** `Theme.of(context).colorScheme`, `AppDimensions`. `Color(0xFF…)` sabiti yazma.
12. **Ölü buton bırakma.** Henüz çalışmayan bir özellik ya gizlenir ya da hiç eklenmez. Boş `onPressed: () {}` ve sahte "kopyalandı" mesajı yasak.
13. **Gönderim butonları** yüklenirken devre dışı kalır (çift gönderim yok); formlarda `maxLength` bulunur.
14. **Testler:** yeni mantık (parser, redirect, provider, repository) için en az bir test yaz. `flutter analyze` ve `flutter test` yeşil olmadan iş bitmiş sayılmaz.
15. **Gizli bilgi:** service_role key hiçbir zaman istemciye girmez. Anon key ve URL ileride `--dart-define-from-file` ile verilecek (Faz 5).

---

## Ürün kapsamı

### Kullanıcılar
- **Giriş:** e-posta veya telefon + 6 haneli OTP (şifresiz). İlk girişte 3 adımlı kayıt: (1) ad + unvan, (2) üniversite, şehir, klinik, deneyim, (3) avatar + biyografi.
- **Unvanlar** (`UserTitle`): Öğrenci, Diş Hekimi, Endodontist, Ortodontist, Periodontolog, Protez Uzmanı, Pedodontist, Çene Cerrahı, Çene Radyoloğu, Oral Diagnoz Uzmanı, Restoratif Diş Tedavisi Uzmanı.
- `is_verified` yalnızca admin onayıyla değişir (Faz 4: diploma doğrulama).

### İçerik
| Tür | Alanlar | Not |
|---|---|---|
| **Vaka** | başlık, açıklama, branş (zorunlu, `DentalBranch`), etiketler, en fazla 10 görsel | Hasta mahremiyeti: yüz ve kimlik bilgisi içermemeli (paylaşırken onay kutusu zorunlu) |
| **Soru** | başlık, detay, etiketler (görsel yükleme henüz yok) | Soru sahibi "En İyi Cevap" seçer (`mark_best_answer` RPC) |
| İş ilanı, pazar yeri | — | Yayın sonrası |

**Branşlar** (`DentalBranch`): Pedodonti, Endodonti, Ortodonti, Periodontoloji, Protetik, Çene Cerrahisi, Çene Radyolojisi, Oral Diagnoz, Restoratif.

### Sosyal
- Beğeni (post ve yorum), yorum ve cevap, takip, kaydetme (bookmark), bire bir DM (realtime), bildirimler.
- Feed sekmeleri: Tümü / Vakalar / Sorular. Sıralama kronolojik (algoritmik feed yayından sonra).
- Arama: Türkçe full-text (başlık + içerik), kullanıcı arama, branş ve tür filtresi.
- Moderasyon: raporla (post, yorum, kullanıcı), engelle (iki yönlü gizler), hesap silme. Kuyruk: `docs/SUPABASE.md` §6.

### Navigasyon
Alt menü: **Ana Sayfa** `/feed` · **Keşfet** `/search` · **Oluştur (+)** (vaka/soru seçimi) · **Mesajlar** `/messages` · **Profil** `/profile`.

Diğer rotalar: `/post/:id` (tek post kartı; bildirim ve deep link hedefi), `/create-case`, `/create-question`, `/chat/:userId`, `/profile/:userId`, `/edit-profile`, `/network/:id`, `/notifications`, `/bookmarks`, `/settings`, `/settings/blocked`, `/legal/:doc`, `/login`, `/register`. Tam liste: `lib/core/router/app_router.dart`.

---

## Tasarım sistemi

- **Renkler:** `lib/core/constants/app_colors.dart`. Primary: Deep Teal `#0D9488` (light) / Cyan Mint `#2DD4BF` (dark). Secondary: Violet `#7C3AED` / Lavender `#A78BFA`.
- **Glass:** `GlassThemeExtension` ile blur, tint ve frost border; widget'lar `PostGlassContainer`, `GlassField`, `GlassBackgroundEffect`.
- **Tipografi:** `app_text_styles.dart` (Material 3 type scale). Font dosyaları henüz bundle'da değil (AUDIT `REL-3`).
- **Ölçüler:** `app_dimensions.dart`. Minimum dokunma alanı 48dp. Metin kontrastı ≥ 4.5:1.
- **Genişletilebilirlik:** ekranlar küçük bağımsız widget'lardan oluşur. Ayarlara yeni bölüm eklemek için `_buildSections` listesine bir `SettingsSection` eklemek yeterli.
