import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Doğrulama sonrası "Hoş geldin" ekranını görmüş kullanıcı id'leri.
/// Cihazda kalıcıdır; çıkışta silinmez (aynı hesapla tekrar girişte gösterilmez).
/// `main` [SharedPreferences] ile override eder.
final welcomedUsersProvider =
    NotifierProvider<WelcomedUsersNotifier, Set<String>>(
      WelcomedUsersNotifier.new,
    );

class WelcomedUsersNotifier extends Notifier<Set<String>> {
  WelcomedUsersNotifier([this._prefs]);

  final SharedPreferences? _prefs;
  static const _key = 'welcomed_users';

  @override
  Set<String> build() => {...?_prefs?.getStringList(_key)};

  void markWelcomed(String uid) {
    if (state.contains(uid)) return;
    state = {...state, uid};
    _prefs?.setStringList(_key, state.toList());
  }
}
