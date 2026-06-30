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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  /// **'Bilinmeyen bir hata oluştu.'**
  String get unknownError;

  /// Ağ hatası mesajı
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı kontrol edin.'**
  String get networkError;

  /// Boş sonuç mesajı
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı.'**
  String get noResults;

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
  /// **'Şikayet Et'**
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

  /// Takibi bırak butonu
  ///
  /// In tr, this message translates to:
  /// **'Takibi Bırak'**
  String get unfollowButton;

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
  /// **'En fazla 10 görsel ekleyebilirsiniz.'**
  String get maxImagesReached;

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
  /// **'Vaka, soru veya kullanıcı ara...'**
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
