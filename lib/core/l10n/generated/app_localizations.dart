import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Uygulamanın adı
  ///
  /// In tr, this message translates to:
  /// **'DentLink'**
  String get appName;

  /// Uygulama sloganı
  ///
  /// In tr, this message translates to:
  /// **'Diş Hekimleri İçin Sosyal Platform'**
  String get appTagline;

  /// Genel yükleniyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// Yeniden deneme butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// Cihaz çevrimdışıyken üstte görünen şerit
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok'**
  String get offlineBanner;

  /// İptal butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// Kaydet butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// Sil butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// Onay butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// Kapat butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// Düzenle butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// Tamam butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get done;

  /// Genel hata başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// Bilinmeyen hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu.'**
  String get unknownError;

  /// Ağ hatası mesajı
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantınızı kontrol edin.'**
  String get networkError;

  /// Boş sonuç mesajı
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı.'**
  String get noResults;

  /// Gönderi bulunamadı hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Gönderi bulunamadı.'**
  String get postNotFound;

  /// Gönderi yükleme hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Gönderi yüklenirken hata oluştu.'**
  String get postLoadError;

  /// Boş feed mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz gönderi yok.'**
  String get emptyFeed;

  /// Tümünü gör bağlantısı
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get seeAll;

  /// Gönderi paylaş seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Gönderiyi Paylaş'**
  String get sharePost;

  /// Şikayet et seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Raporla'**
  String get report;

  /// Daha fazla seçenek tooltip
  ///
  /// In tr, this message translates to:
  /// **'Daha Fazla Seçenek'**
  String get moreOptions;

  /// Alt navigasyon - Ana Sayfa
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get navFeed;

  /// Alt navigasyon - Keşfet
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get navExplore;

  /// Alt navigasyon - Oluştur
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get navCreate;

  /// Alt navigasyon - Mesajlar
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get navMessages;

  /// Alt navigasyon - Profil
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// Giriş ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hoşgeldin!'**
  String get loginTitle;

  /// Giriş ekranı alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için giriş yap'**
  String get loginSubtitle;

  /// Giriş butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get loginButton;

  /// giriş butonuyla oauth arasındaki metin
  ///
  /// In tr, this message translates to:
  /// **'ya da'**
  String get textBeetweenLoginAndOauth;

  /// Google giriş butonu
  ///
  /// In tr, this message translates to:
  /// **'Google ile devam et'**
  String get loginWithGoogle;

  /// Telefon giriş butonu
  ///
  /// In tr, this message translates to:
  /// **'Telefon ile Giriş Yap'**
  String get loginWithPhone;

  /// Kayıt yönlendirme metni
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu?'**
  String get noAccount;

  /// Kayıt ol bağlantısı
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get registerNow;

  /// Kayıt ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get registerTitle;

  /// Kayıt ol butonu etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get registerButton;

  /// Giriş yönlendirme metni
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı?'**
  String get alreadyHaveAccount;

  /// Giriş yap bağlantısı
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get signIn;

  /// Şifremi unuttum bağlantısı
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPassword;

  /// E-posta alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// E-posta alanı ipucu
  ///
  /// In tr, this message translates to:
  /// **'e-posta adresini gir'**
  String get emailHint;

  /// Şifre alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// Şifre alanı ipucu
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi girin'**
  String get passwordHint;

  /// Şifre onay alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Onayla'**
  String get confirmPassword;

  /// Telefon alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get phone;

  /// Telefon alanı ipucu
  ///
  /// In tr, this message translates to:
  /// **'+90 5xx xxx xx xx'**
  String get phoneHint;

  /// Doğrulama kodu alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Kodu'**
  String get verificationCode;

  /// Kod gönder butonu
  ///
  /// In tr, this message translates to:
  /// **'Kod Gönder'**
  String get sendCode;

  /// Kodu doğrula butonu
  ///
  /// In tr, this message translates to:
  /// **'Kodu Doğrula'**
  String get verifyCode;

  /// Unvan seçim ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Unvan Seçimi'**
  String get titleSelection;

  /// Unvan seçim alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kendinizi en iyi tanımlayan unvanı seçin'**
  String get titleSelectionSubtitle;

  /// Öğrenci unvanı
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci'**
  String get titleStudent;

  /// Genel pratisyen unvanı
  ///
  /// In tr, this message translates to:
  /// **'Genel Diş Hekimi'**
  String get titleGeneralDentist;

  /// Endodontist unvanı
  ///
  /// In tr, this message translates to:
  /// **'Endodontist'**
  String get titleEndodontist;

  /// Ortodontist unvanı
  ///
  /// In tr, this message translates to:
  /// **'Ortodontist'**
  String get titleOrthodontist;

  /// Periodontolog unvanı
  ///
  /// In tr, this message translates to:
  /// **'Periodontolog'**
  String get titlePeriodontologist;

  /// Protez uzmanı unvanı
  ///
  /// In tr, this message translates to:
  /// **'Protez Uzmanı'**
  String get titleProsthodontist;

  /// Pedodontist unvanı
  ///
  /// In tr, this message translates to:
  /// **'Pedodontist'**
  String get titlePedodontist;

  /// Ağız, Diş ve Çene Cerrahı unvanı
  ///
  /// In tr, this message translates to:
  /// **'Ağız, Diş ve Çene Cerrahı'**
  String get titleOralSurgeon;

  /// Radyoloji uzmanı unvanı
  ///
  /// In tr, this message translates to:
  /// **'Ağız, Diş ve Çene Radyoloğu'**
  String get titleOralRadiologist;

  /// Oral diagnoz uzmanı unvanı
  ///
  /// In tr, this message translates to:
  /// **'Oral Diagnoz Uzmanı'**
  String get titleOralDiagnostics;

  /// Restoratif uzmanı unvanı
  ///
  /// In tr, this message translates to:
  /// **'Restoratif Diş Tedavisi Uzmanı'**
  String get titleRestorativeDentistry;

  /// Profil ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// Profili düzenle butonu
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get editProfile;

  /// Takipçi etiketi
  ///
  /// In tr, this message translates to:
  /// **'Takipçi'**
  String get followers;

  /// Takip edilen etiketi
  ///
  /// In tr, this message translates to:
  /// **'Takip'**
  String get following;

  /// Gönderi sayısı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gönderi'**
  String get posts;

  /// Takip et butonu
  ///
  /// In tr, this message translates to:
  /// **'Takip Et'**
  String get followButton;

  /// Takip edilen kullanıcıda buton; basınca takip bırakılır
  ///
  /// In tr, this message translates to:
  /// **'Takip Ediliyor'**
  String get followingButton;

  /// Mesaj gönder butonu
  ///
  /// In tr, this message translates to:
  /// **'Mesaj Gönder'**
  String get messageButton;

  /// Biyografi alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Biyografi'**
  String get bio;

  /// Üniversite alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Üniversite'**
  String get university;

  /// Şehir alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get city;

  /// Deneyim yılı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Deneyim Yılı'**
  String get experienceYears;

  /// Çalışma yeri etiketi
  ///
  /// In tr, this message translates to:
  /// **'Çalıştığı Klinik/Hastane'**
  String get workplace;

  /// Rozetler sekmesi
  ///
  /// In tr, this message translates to:
  /// **'Rozetlerim'**
  String get profileBadges;

  /// Vakalar sekmesi
  ///
  /// In tr, this message translates to:
  /// **'Vakalarım'**
  String get profileCases;

  /// Sorular sekmesi
  ///
  /// In tr, this message translates to:
  /// **'Sorularım'**
  String get profileQuestions;

  /// Kaydedilenler sekmesi
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilenler'**
  String get profileSaved;

  /// Vaka gönderi türü etiketi
  ///
  /// In tr, this message translates to:
  /// **'Vaka'**
  String get casePost;

  /// Soru gönderi türü etiketi
  ///
  /// In tr, this message translates to:
  /// **'Soru'**
  String get questionPost;

  /// Gönderi oluştur başlığı
  ///
  /// In tr, this message translates to:
  /// **'Gönderi Oluştur'**
  String get createPost;

  /// Vaka paylaş butonu/başlığı
  ///
  /// In tr, this message translates to:
  /// **'Vaka Paylaş'**
  String get createCase;

  /// Soru sor butonu/başlığı
  ///
  /// In tr, this message translates to:
  /// **'Soru Sor'**
  String get createQuestion;

  /// Gönderi başlığı alanı
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get postTitle;

  /// Gönderi içerik alanı
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get postContent;

  /// Branş seçim alanı
  ///
  /// In tr, this message translates to:
  /// **'Branş'**
  String get postBranch;

  /// Etiketler alanı
  ///
  /// In tr, this message translates to:
  /// **'Etiketler'**
  String get postTags;

  /// Etiket ekleme ipucu
  ///
  /// In tr, this message translates to:
  /// **'Etiket Ekle'**
  String get addTag;

  /// Görsel ekleme butonu
  ///
  /// In tr, this message translates to:
  /// **'Görsel Ekle'**
  String get addImages;

  /// Maksimum görsel uyarısı
  ///
  /// In tr, this message translates to:
  /// **'En fazla {count} görsel ekleyebilirsiniz.'**
  String maxImagesReached(int count);

  /// Yayınla butonu
  ///
  /// In tr, this message translates to:
  /// **'Yayınla'**
  String get publish;

  /// Pedodonti branşı
  ///
  /// In tr, this message translates to:
  /// **'Pedodonti'**
  String get branchPedodontics;

  /// Endodonti branşı
  ///
  /// In tr, this message translates to:
  /// **'Endodonti'**
  String get branchEndodontics;

  /// Ortodonti branşı
  ///
  /// In tr, this message translates to:
  /// **'Ortodonti'**
  String get branchOrthodontics;

  /// Periodontoloji branşı
  ///
  /// In tr, this message translates to:
  /// **'Periodontoloji'**
  String get branchPeriodontology;

  /// Protetik Diş Tedavisi branşı
  ///
  /// In tr, this message translates to:
  /// **'Protetik Diş Tedavisi'**
  String get branchProsthodontics;

  /// Ağız, Diş ve Çene Cerrahisi branşı
  ///
  /// In tr, this message translates to:
  /// **'Ağız, Diş ve Çene Cerrahisi'**
  String get branchOralSurgery;

  /// Ağız, Diş ve Çene Radyolojisi branşı
  ///
  /// In tr, this message translates to:
  /// **'Ağız, Diş ve Çene Radyolojisi'**
  String get branchOralRadiology;

  /// Oral Diagnoz branşı
  ///
  /// In tr, this message translates to:
  /// **'Oral Diagnoz'**
  String get branchOralDiagnosis;

  /// Restoratif Diş Tedavisi branşı
  ///
  /// In tr, this message translates to:
  /// **'Restoratif Diş Tedavisi'**
  String get branchRestorativeDentistry;

  /// Kronolojik akış tab etiketi
  ///
  /// In tr, this message translates to:
  /// **'Son Eklenen'**
  String get feedChronological;

  /// Algoritmik akış tab etiketi
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan'**
  String get feedAlgorithmic;

  /// Akış filtre - Tümü
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get feedFilterAll;

  /// Akış filtre - Vakalar
  ///
  /// In tr, this message translates to:
  /// **'Vakalar'**
  String get feedFilterCases;

  /// Akış filtre - Sorular
  ///
  /// In tr, this message translates to:
  /// **'Sorular'**
  String get feedFilterQuestions;

  /// Akış filtre - İş ilanları (henüz içerik yok)
  ///
  /// In tr, this message translates to:
  /// **'İş İlanları'**
  String get feedFilterJobs;

  /// No description provided for @feedJobsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz iş ilanı yok'**
  String get feedJobsEmptyTitle;

  /// No description provided for @feedJobsEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İş ilanları yakında burada olacak.'**
  String get feedJobsEmptySubtitle;

  /// Profildeki vakalar sekmesi başlığı
  ///
  /// In tr, this message translates to:
  /// **'Vakalar'**
  String get casesTabLabelInProfile;

  /// Profildeki sorular sekmesi başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sorular'**
  String get questionsTabLabelInProfile;

  /// Beğeni sayısı
  ///
  /// In tr, this message translates to:
  /// **'{count} beğeni'**
  String likesCount(int count);

  /// Yorum sayısı
  ///
  /// In tr, this message translates to:
  /// **'{count} yorum'**
  String commentsCount(int count);

  /// Cevap sayısı
  ///
  /// In tr, this message translates to:
  /// **'{count} cevap'**
  String answersCount(int count);

  /// En iyi cevap rozeti
  ///
  /// In tr, this message translates to:
  /// **'En İyi Cevap'**
  String get bestAnswer;

  /// En iyi cevap işaretle butonu
  ///
  /// In tr, this message translates to:
  /// **'En İyi Cevap Seç'**
  String get markAsBestAnswer;

  /// Yorum yazma alanı ipucu
  ///
  /// In tr, this message translates to:
  /// **'Yorum yaz...'**
  String get writeComment;

  /// Cevap yazma alanı ipucu
  ///
  /// In tr, this message translates to:
  /// **'Cevabını yaz...'**
  String get writeAnswer;

  /// Mesaj gönder butonu
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get sendMessage;

  /// Keşfet ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get exploreTitle;

  /// Arama alanı ipucu
  ///
  /// In tr, this message translates to:
  /// **'Vaka, hekim veya soru ara...'**
  String get searchHint;

  /// Branş filtresi
  ///
  /// In tr, this message translates to:
  /// **'Branşa Göre'**
  String get filterByBranch;

  /// Unvan filtresi
  ///
  /// In tr, this message translates to:
  /// **'Unvana Göre'**
  String get filterByTitle;

  /// İçerik türü filtresi
  ///
  /// In tr, this message translates to:
  /// **'Türe Göre'**
  String get filterByType;

  /// Etiket filtresi
  ///
  /// In tr, this message translates to:
  /// **'Etikete Göre'**
  String get filterByTag;

  /// Filtreleri temizle butonu
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri Temizle'**
  String get clearFilters;

  /// Mesajlar ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get messagesTitle;

  /// Boş mesaj listesi
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesajınız yok.'**
  String get noMessages;

  /// Mesaj yazma alanı ipucu
  ///
  /// In tr, this message translates to:
  /// **'Mesajınızı yazın...'**
  String get typeMessage;

  /// Bildirimler ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsTitle;

  /// Boş bildirim listesi
  ///
  /// In tr, this message translates to:
  /// **'Henüz bildiriminiz yok.'**
  String get noNotifications;

  /// Bildirim listesi yükleme hatası
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler yüklenemedi.'**
  String get notificationsLoadError;

  /// Beğeni bildirimi
  ///
  /// In tr, this message translates to:
  /// **'{name} gönderinizi beğendi.'**
  String notifLiked(String name);

  /// Yorum bildirimi
  ///
  /// In tr, this message translates to:
  /// **'{name} gönderinize yorum yaptı.'**
  String notifCommented(String name);

  /// Takip bildirimi
  ///
  /// In tr, this message translates to:
  /// **'{name} sizi takip etmeye başladı.'**
  String notifFollowed(String name);

  /// Mesaj bildirimi
  ///
  /// In tr, this message translates to:
  /// **'{name} size mesaj gönderdi.'**
  String notifMessage(String name);

  /// Kaydedilenler ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilenler'**
  String get bookmarksTitle;

  /// Boş kayıt listesi
  ///
  /// In tr, this message translates to:
  /// **'Henüz kaydedilen gönderi yok.'**
  String get noBookmarks;

  /// Ayarlar ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// Tema ayarı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// Açık tema seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settingsThemeLight;

  /// Koyu tema seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settingsThemeDark;

  /// Sistem teması seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Sistem Varsayılanı'**
  String get settingsThemeSystem;

  /// Dil ayarı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// Bildirim ayarları etiketi
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsNotifications;

  /// Hesap ayarları etiketi
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get settingsAccount;

  /// Çıkış yap butonu
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get settingsLogout;

  /// Çıkış onay mesajı
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapmak istediğinize emin misiniz?'**
  String get settingsLogoutConfirm;

  /// Türkçe dil seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// İngilizce dil seçeneği
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get languageEnglish;

  /// Uzman rozeti adı
  ///
  /// In tr, this message translates to:
  /// **'Uzman'**
  String get badgeExpert;

  /// Popüler rozeti adı
  ///
  /// In tr, this message translates to:
  /// **'Popüler'**
  String get badgePopular;

  /// Yardımsever rozeti adı
  ///
  /// In tr, this message translates to:
  /// **'Yardımsever'**
  String get badgeHelper;

  /// Yeni üye rozeti adı
  ///
  /// In tr, this message translates to:
  /// **'Yeni Üye'**
  String get badgeNewMember;

  /// Zorunlu alan hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Bu alan zorunludur.'**
  String get validationRequired;

  /// Geçersiz e-posta hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi girin.'**
  String get validationEmailInvalid;

  /// Şifre minimum uzunluk hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 8 karakter olmalıdır.'**
  String get validationPasswordMinLength;

  /// Şifre uyuşmazlığı hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get validationPasswordMismatch;

  /// Geçersiz telefon hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir telefon numarası girin.'**
  String get validationPhoneInvalid;

  /// No description provided for @notificationLiked.
  ///
  /// In tr, this message translates to:
  /// **'{actorName} gönderini beğendi.'**
  String notificationLiked(String actorName);

  /// No description provided for @notificationCommented.
  ///
  /// In tr, this message translates to:
  /// **'{actorName} gönderine yorum yaptı.'**
  String notificationCommented(String actorName);

  /// No description provided for @notificationFollowed.
  ///
  /// In tr, this message translates to:
  /// **'{actorName} seni takip etmeye başladı.'**
  String notificationFollowed(String actorName);

  /// No description provided for @notificationMessaged.
  ///
  /// In tr, this message translates to:
  /// **'{actorName} sana mesaj gönderdi.'**
  String notificationMessaged(String actorName);

  /// No description provided for @notificationBestAnswer.
  ///
  /// In tr, this message translates to:
  /// **'{actorName} cevabını en iyi cevap olarak seçti.'**
  String notificationBestAnswer(String actorName);

  /// No description provided for @notificationBadge.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir rozet kazandın!'**
  String get notificationBadge;

  /// No description provided for @authProfileLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Profilin yüklenemedi. İnternet bağlantını kontrol edip tekrar dene.'**
  String get authProfileLoadError;

  /// No description provided for @profileMessageButton.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get profileMessageButton;

  /// No description provided for @postDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiyi sil'**
  String get postDeleteTitle;

  /// No description provided for @postDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu gönderi kalıcı olarak silinecek. Emin misin?'**
  String get postDeleteConfirm;

  /// No description provided for @postDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi silindi.'**
  String get postDeleted;

  /// No description provided for @profileNoPosts.
  ///
  /// In tr, this message translates to:
  /// **'Henüz gönderi yok.'**
  String get profileNoPosts;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dön'**
  String get back;

  /// No description provided for @chatEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok. İlk mesajı siz gönderin!'**
  String get chatEmpty;

  /// No description provided for @chatLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar yüklenemedi.'**
  String get chatLoadError;

  /// No description provided for @chatSendError.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderilemedi, lütfen tekrar deneyin.'**
  String get chatSendError;

  /// Gönderi düzenleme ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Gönderiyi Düzenle'**
  String get editPost;

  /// No description provided for @postUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi güncellendi.'**
  String get postUpdated;

  /// No description provided for @pickFromGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden Seç'**
  String get pickFromGallery;

  /// No description provided for @pickFromCamera.
  ///
  /// In tr, this message translates to:
  /// **'Kameradan Çek'**
  String get pickFromCamera;

  /// No description provided for @changePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı değiştir'**
  String get changePhoto;

  /// No description provided for @validationExperience.
  ///
  /// In tr, this message translates to:
  /// **'0 ile 70 arasında bir sayı girin.'**
  String get validationExperience;

  /// Post kartında kısaltılmış içeriğin devamını açan bağlantı
  ///
  /// In tr, this message translates to:
  /// **'Devamını oku'**
  String get readMore;

  /// Sayfalı listede sonraki sayfayı elle yükleyen buton
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla göster'**
  String get showMore;

  /// No description provided for @discardChangesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikler kaybolacak'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetmeden çıkmak istediğinize emin misiniz?'**
  String get discardChangesMessage;

  /// Kaydedilmemiş formdan çıkışı onaylayan buton
  ///
  /// In tr, this message translates to:
  /// **'Çık'**
  String get discardChangesConfirm;

  /// No description provided for @newMessage.
  ///
  /// In tr, this message translates to:
  /// **'Yeni mesaj'**
  String get newMessage;

  /// No description provided for @like.
  ///
  /// In tr, this message translates to:
  /// **'Beğen'**
  String get like;

  /// No description provided for @titleUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get titleUnknown;

  /// No description provided for @errorAuthRequired.
  ///
  /// In tr, this message translates to:
  /// **'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.'**
  String get errorAuthRequired;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için yetkiniz yok.'**
  String get errorPermissionDenied;

  /// No description provided for @errorNotFound.
  ///
  /// In tr, this message translates to:
  /// **'İçerik bulunamadı veya silinmiş.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In tr, this message translates to:
  /// **'Girdiğiniz içerik geçerli değil.'**
  String get errorValidation;

  /// No description provided for @errorConflict.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt zaten var.'**
  String get errorConflict;

  /// No description provided for @errorServer.
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun oluştu, lütfen tekrar deneyin.'**
  String get errorServer;

  /// No description provided for @errorMediaPermission.
  ///
  /// In tr, this message translates to:
  /// **'Erişim izni verilmedi. Telefon ayarlarından izin verebilirsiniz.'**
  String get errorMediaPermission;

  /// No description provided for @otpTooManyAttempts.
  ///
  /// In tr, this message translates to:
  /// **'Çok sık deneme yaptınız. {seconds} saniye sonra tekrar deneyin.'**
  String otpTooManyAttempts(int seconds);

  /// No description provided for @loginSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yapıldı!'**
  String get loginSuccess;

  /// No description provided for @success.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// No description provided for @otpInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Kod hatalı veya süresi dolmuş'**
  String get otpInvalid;

  /// No description provided for @otpSendFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kod gönderilemedi. Lütfen tekrar deneyin.'**
  String get otpSendFailed;

  /// No description provided for @validationNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad alanı zorunludur'**
  String get validationNameRequired;

  /// No description provided for @validationTitleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir unvan seçin'**
  String get validationTitleRequired;

  /// No description provided for @registerCreatingProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil oluşturuluyor...'**
  String get registerCreatingProfile;

  /// No description provided for @loginInputHint.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya telefon numarası'**
  String get loginInputHint;

  /// No description provided for @loginHeaderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya telefon numaranızla giriş yapın'**
  String get loginHeaderSubtitle;

  /// No description provided for @otpSentTo.
  ///
  /// In tr, this message translates to:
  /// **'{destination} adresine gönderilen kodu girin'**
  String otpSentTo(String destination);

  /// No description provided for @resendCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Tekrar Gönder'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Tekrar Gönder ({seconds}s)'**
  String resendCodeIn(int seconds);

  /// No description provided for @changeEmailOrPhone.
  ///
  /// In tr, this message translates to:
  /// **'E-posta/Telefon Değiştir'**
  String get changeEmailOrPhone;

  /// No description provided for @backToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Girişe Dön'**
  String get backToLogin;

  /// No description provided for @backShort.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get backShort;

  /// No description provided for @completeProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profilimi Tamamla'**
  String get completeProfile;

  /// No description provided for @continueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueAction;

  /// No description provided for @registerDoneTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydınız Tamamlandı!'**
  String get registerDoneTitle;

  /// No description provided for @registerDoneMessage.
  ///
  /// In tr, this message translates to:
  /// **'DentLink dünyasına hoş geldiniz. Profiliniz oluşturuldu.'**
  String get registerDoneMessage;

  /// No description provided for @skip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get skip;

  /// No description provided for @stepOf.
  ///
  /// In tr, this message translates to:
  /// **'Adım {current} / {total}'**
  String stepOf(int current, int total);

  /// No description provided for @registerStepBasic.
  ///
  /// In tr, this message translates to:
  /// **'Temel Bilgiler'**
  String get registerStepBasic;

  /// No description provided for @registerStepProfessional.
  ///
  /// In tr, this message translates to:
  /// **'Mesleki Bilgiler'**
  String get registerStepProfessional;

  /// No description provided for @registerStepDetails.
  ///
  /// In tr, this message translates to:
  /// **'Profil Detayları'**
  String get registerStepDetails;

  /// No description provided for @registerStepOneTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sizi Tanıyalım'**
  String get registerStepOneTitle;

  /// No description provided for @registerStepOneSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen adınızı girin ve uzmanlık alanınızı seçin.'**
  String get registerStepOneSubtitle;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @yourTitle.
  ///
  /// In tr, this message translates to:
  /// **'Unvanınız'**
  String get yourTitle;

  /// No description provided for @registerStepTwoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Profesyonel geçmişinizi doldurarak diş hekimleri ağı ile daha iyi etkileşim kurun (İsteğe bağlı).'**
  String get registerStepTwoSubtitle;

  /// No description provided for @registerStepThreeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil fotoğrafınızı seçin ve kısa bir biyografi ekleyin (İsteğe bağlı).'**
  String get registerStepThreeSubtitle;

  /// No description provided for @removePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı Kaldır'**
  String get removePhoto;

  /// No description provided for @bioHint.
  ///
  /// In tr, this message translates to:
  /// **'Biyografi (Kendinizden kısaca bahsedin)'**
  String get bioHint;

  /// No description provided for @pageNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa bulunamadı: {uri}'**
  String pageNotFound(String uri);

  /// No description provided for @backToLoginPage.
  ///
  /// In tr, this message translates to:
  /// **'Giriş sayfasına dön'**
  String get backToLoginPage;

  /// No description provided for @bookmarksEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilen gönderi yok'**
  String get bookmarksEmptyTitle;

  /// No description provided for @bookmarksEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Beğendiğiniz vakaları ve soruları kaydedin,\nburadan kolayca erişin.'**
  String get bookmarksEmptySubtitle;

  /// No description provided for @bookmarksLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilenler yüklenemedi.'**
  String get bookmarksLoadError;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilenlerden kaldırıldı'**
  String get bookmarkRemoved;

  /// No description provided for @undo.
  ///
  /// In tr, this message translates to:
  /// **'Geri Al'**
  String get undo;

  /// No description provided for @feedEmptyFiltered.
  ///
  /// In tr, this message translates to:
  /// **'Seçili filtreye uygun gönderi bulunamadı.'**
  String get feedEmptyFiltered;

  /// No description provided for @feedEmptyAll.
  ///
  /// In tr, this message translates to:
  /// **'Akışta henüz hiç paylaşım yapılmamış.'**
  String get feedEmptyAll;

  /// No description provided for @feedLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Akış yüklenirken bir hata oluştu.'**
  String get feedLoadError;

  /// No description provided for @searchMinChars.
  ///
  /// In tr, this message translates to:
  /// **'Aramak için en az 2 karakter girin.'**
  String get searchMinChars;

  /// No description provided for @userNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bulunamadı.'**
  String get userNotFound;

  /// No description provided for @messagesSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlarda ara...'**
  String get messagesSearchHint;

  /// No description provided for @conversationsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmalar yüklenemedi'**
  String get conversationsLoadError;

  /// No description provided for @markAllRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Okundu İşaretle'**
  String get markAllRead;

  /// No description provided for @joinDiscussionHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesleki tartışmaya katılın...'**
  String get joinDiscussionHint;

  /// No description provided for @validationBranchRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir branş seçin.'**
  String get validationBranchRequired;

  /// No description provided for @caseImageRequired.
  ///
  /// In tr, this message translates to:
  /// **'Vaka için en az bir görsel eklemelisiniz.'**
  String get caseImageRequired;

  /// No description provided for @caseShared.
  ///
  /// In tr, this message translates to:
  /// **'Vaka başarıyla paylaşıldı!'**
  String get caseShared;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @caseTitleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vaka Başlığı'**
  String get caseTitleLabel;

  /// No description provided for @caseTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Mandibular 1. Molar Endodontik Tedavi'**
  String get caseTitleHint;

  /// No description provided for @validationTitleEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Başlık boş bırakılamaz'**
  String get validationTitleEmpty;

  /// No description provided for @caseContentHint.
  ///
  /// In tr, this message translates to:
  /// **'Vakanın hikayesi, teşhis, tedavi planı ve uygulanan işlemler...'**
  String get caseContentHint;

  /// No description provided for @validationDescriptionEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama boş bırakılamaz'**
  String get validationDescriptionEmpty;

  /// No description provided for @questionShared.
  ///
  /// In tr, this message translates to:
  /// **'Sorunuz başarıyla paylaşıldı!'**
  String get questionShared;

  /// No description provided for @questionTitleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Soru Başlığı'**
  String get questionTitleLabel;

  /// No description provided for @questionTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Zirkonyum kaplama sonrası hassasiyet'**
  String get questionTitleHint;

  /// No description provided for @questionContentLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sorunun Detayları'**
  String get questionContentLabel;

  /// No description provided for @questionContentHint.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştığınız problemi veya merak ettiğiniz konuyu detaylıca açıklayın...'**
  String get questionContentHint;

  /// No description provided for @validationContentEmpty.
  ///
  /// In tr, this message translates to:
  /// **'İçerik boş bırakılamaz'**
  String get validationContentEmpty;

  /// No description provided for @selectBranch.
  ///
  /// In tr, this message translates to:
  /// **'Branş Seç'**
  String get selectBranch;

  /// No description provided for @unlike.
  ///
  /// In tr, this message translates to:
  /// **'Beğeniyi geri al'**
  String get unlike;

  /// No description provided for @noCommentsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yapılmamış. İlk yorumu siz ekleyin!'**
  String get noCommentsYet;

  /// No description provided for @noAnswersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz cevap yazılmamış. İlk siz cevaplayın!'**
  String get noAnswersYet;

  /// No description provided for @bestAnswerUnmarked.
  ///
  /// In tr, this message translates to:
  /// **'En iyi cevap seçimi kaldırıldı.'**
  String get bestAnswerUnmarked;

  /// No description provided for @bestAnswerMarked.
  ///
  /// In tr, this message translates to:
  /// **'En iyi cevap başarıyla seçildi! 🎉'**
  String get bestAnswerMarked;

  /// No description provided for @deletedUser.
  ///
  /// In tr, this message translates to:
  /// **'[Silinmiş Kullanıcı]'**
  String get deletedUser;

  /// No description provided for @unmarkSelection.
  ///
  /// In tr, this message translates to:
  /// **'Seçimi Kaldır'**
  String get unmarkSelection;

  /// Yorumlar penceresinin başlığı (vaka)
  ///
  /// In tr, this message translates to:
  /// **'Tartışma'**
  String get discussion;

  /// No description provided for @professionalDiscussion.
  ///
  /// In tr, this message translates to:
  /// **'Mesleki Tartışma'**
  String get professionalDiscussion;

  /// No description provided for @commentsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar yüklenemedi.'**
  String get commentsLoadError;

  /// No description provided for @answersWithCount.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplar ({count})'**
  String answersWithCount(int count);

  /// No description provided for @answersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplar'**
  String get answersTitle;

  /// No description provided for @answersLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplar yüklenemedi.'**
  String get answersLoadError;

  /// No description provided for @images.
  ///
  /// In tr, this message translates to:
  /// **'Görseller'**
  String get images;

  /// No description provided for @addPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Ekle'**
  String get addPhoto;

  /// No description provided for @addTagHint.
  ///
  /// In tr, this message translates to:
  /// **'Etiket ekle (Enter\'a bas)'**
  String get addTagHint;

  /// No description provided for @profileUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Profil güncellendi'**
  String get profileUpdated;

  /// No description provided for @userInfoNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bilgisi bulunamadı'**
  String get userInfoNotFound;

  /// No description provided for @fullNameRequiredLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad - Soyad *'**
  String get fullNameRequiredLabel;

  /// No description provided for @titleRequiredLabel.
  ///
  /// In tr, this message translates to:
  /// **'Unvan *'**
  String get titleRequiredLabel;

  /// No description provided for @networkTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ağ'**
  String get networkTitle;

  /// No description provided for @followersTab.
  ///
  /// In tr, this message translates to:
  /// **'Takipçiler'**
  String get followersTab;

  /// No description provided for @followingTab.
  ///
  /// In tr, this message translates to:
  /// **'Takip Edilenler'**
  String get followingTab;

  /// No description provided for @noFollowersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz takipçisi yok.'**
  String get noFollowersYet;

  /// No description provided for @noFollowingYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimseyi takip etmiyor.'**
  String get noFollowingYet;

  /// No description provided for @usersLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar yüklenirken bir hata oluştu.'**
  String get usersLoadError;

  /// No description provided for @mutualFollowedBy.
  ///
  /// In tr, this message translates to:
  /// **'{others, plural, =0{{name} takip ediyor} other{{name} ve {others} diğer kişi takip ediyor}}'**
  String mutualFollowedBy(String name, int others);

  /// No description provided for @badgesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get badgesTitle;

  /// No description provided for @statFollowing.
  ///
  /// In tr, this message translates to:
  /// **'Takip Edilen'**
  String get statFollowing;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç Bulunamadı'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoPosts.
  ///
  /// In tr, this message translates to:
  /// **'Arama kriterlerinize uygun gönderi bulunamadı.'**
  String get searchNoPosts;

  /// No description provided for @searchNoUsers.
  ///
  /// In tr, this message translates to:
  /// **'Arama kriterlerinize uygun kullanıcı bulunamadı.'**
  String get searchNoUsers;

  /// No description provided for @searchUsersTab.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar'**
  String get searchUsersTab;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arama Yapın'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Diş hekimliği dünyasında vaka, soru veya meslektaş arayın.'**
  String get searchEmptySubtitle;

  /// No description provided for @searchPostsTab.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiler'**
  String get searchPostsTab;

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// No description provided for @contentType.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Türü'**
  String get contentType;

  /// No description provided for @allBranches.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Branşlar'**
  String get allBranches;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// No description provided for @settingsChooseTheme.
  ///
  /// In tr, this message translates to:
  /// **'Tema Seçin'**
  String get settingsChooseTheme;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Dili'**
  String get settingsAppLanguage;

  /// No description provided for @settingsChooseLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get settingsChooseLanguage;

  /// No description provided for @settingsBlocked.
  ///
  /// In tr, this message translates to:
  /// **'Engellenenler'**
  String get settingsBlocked;

  /// No description provided for @settingsAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get settingsAbout;

  /// No description provided for @settingsTerms.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsAppVersion.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Sürümü'**
  String get settingsAppVersion;

  /// No description provided for @createSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne paylaşmak istersin?'**
  String get createSheetTitle;

  /// No description provided for @createSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Klinik vakalarını ve sorularını paylaşarak topluluğa katkı sağla.'**
  String get createSheetSubtitle;

  /// No description provided for @createCaseSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Klinik vakalarını görsellerle paylaş, meslektaşlarından görüş al.'**
  String get createCaseSubtitle;

  /// No description provided for @createQuestionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesleki sorularını toplulukla paylaş, en iyi cevabı bul.'**
  String get createQuestionSubtitle;

  /// No description provided for @timeJustNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{n} dk önce'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{n} saat önce'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{n} gün önce'**
  String timeDaysAgo(int n);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In tr, this message translates to:
  /// **'{n} hafta önce'**
  String timeWeeksAgo(int n);

  /// No description provided for @reportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neden raporluyorsun?'**
  String get reportTitle;

  /// No description provided for @reportReasonSpam.
  ///
  /// In tr, this message translates to:
  /// **'Spam veya reklam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In tr, this message translates to:
  /// **'Taciz veya zorbalık'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonPatientPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Hasta mahremiyeti ihlali (yüz, isim, kimlik)'**
  String get reportReasonPatientPrivacy;

  /// No description provided for @reportReasonMisinformation.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış veya tehlikeli bilgi'**
  String get reportReasonMisinformation;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz içerik'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get reportReasonOther;

  /// No description provided for @reportNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Ek açıklama (isteğe bağlı)'**
  String get reportNoteHint;

  /// No description provided for @reportSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Raporu Gönder'**
  String get reportSubmit;

  /// No description provided for @reportSent.
  ///
  /// In tr, this message translates to:
  /// **'Raporun alındı, inceleyeceğiz. Teşekkürler.'**
  String get reportSent;

  /// No description provided for @blockUser.
  ///
  /// In tr, this message translates to:
  /// **'Engelle'**
  String get blockUser;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı engellensin mi?'**
  String get blockConfirmTitle;

  /// No description provided for @blockConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Birbirinizin gönderilerini ve yorumlarını görmeyeceksiniz, birbirinize mesaj atamayacaksınız. Takipler kaldırılır. Engeli Ayarlar → Engellenenler\'den kaldırabilirsin.'**
  String get blockConfirmBody;

  /// No description provided for @userBlocked.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı engellendi'**
  String get userBlocked;

  /// No description provided for @unblock.
  ///
  /// In tr, this message translates to:
  /// **'Engeli Kaldır'**
  String get unblock;

  /// No description provided for @userUnblocked.
  ///
  /// In tr, this message translates to:
  /// **'Engel kaldırıldı'**
  String get userUnblocked;

  /// No description provided for @blockedEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Engellediğin kimse yok'**
  String get blockedEmpty;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get settingsDeleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın kalıcı olarak silinsin mi?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In tr, this message translates to:
  /// **'Profilin, gönderilerin, yorumların, mesajların (karşı taraftaki sohbet dahil) ve yüklediğin tüm görseller kalıcı olarak silinir. Bu işlem geri alınamaz.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirmWord.
  ///
  /// In tr, this message translates to:
  /// **'SİL'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onaylamak için {word} yaz'**
  String deleteAccountTypeToConfirm(String word);

  /// No description provided for @legalKvkk.
  ///
  /// In tr, this message translates to:
  /// **'KVKK Aydınlatma Metni'**
  String get legalKvkk;

  /// No description provided for @registerAcceptTerms.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları\'nı okudum ve kabul ediyorum. KVKK Aydınlatma Metni\'ni ve Gizlilik Politikası\'nı okudum.'**
  String get registerAcceptTerms;

  /// No description provided for @validationTermsRequired.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için kullanım koşullarını kabul etmelisin'**
  String get validationTermsRequired;

  /// No description provided for @casePrivacyConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Görseller ve açıklama hastanın yüzünü, adını veya kimliğini ortaya çıkaracak bilgi içermiyor.'**
  String get casePrivacyConfirm;

  /// No description provided for @casePrivacyRequired.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşmadan önce hasta mahremiyeti onayını işaretlemelisin'**
  String get casePrivacyRequired;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapılsın mı?'**
  String get logoutConfirmTitle;

  /// No description provided for @chatToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get chatYesterday;

  /// No description provided for @imagesRejectedSize.
  ///
  /// In tr, this message translates to:
  /// **'Çok küçük ya da çok dar görseller eklenmedi.'**
  String get imagesRejectedSize;

  /// Yorumun altındaki yanıt butonu
  ///
  /// In tr, this message translates to:
  /// **'Yanıtla'**
  String get reply;

  /// No description provided for @showReplies.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} yanıtı göster}}'**
  String showReplies(int count);

  /// No description provided for @hideReplies.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtları gizle'**
  String get hideReplies;

  /// No description provided for @replyingTo.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtlanan: {name}'**
  String replyingTo(String name);

  /// No description provided for @writeReply.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtını yaz...'**
  String get writeReply;

  /// No description provided for @notificationReplied.
  ///
  /// In tr, this message translates to:
  /// **'{actorName} yorumuna yanıt verdi.'**
  String notificationReplied(String actorName);

  /// No description provided for @profileExperience.
  ///
  /// In tr, this message translates to:
  /// **'{years} yıl deneyim'**
  String profileExperience(int years);

  /// No description provided for @verifiedAccount.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış hesap'**
  String get verifiedAccount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
