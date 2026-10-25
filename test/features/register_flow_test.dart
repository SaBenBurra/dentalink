import 'dart:io';

import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';
import '../../integration_test/mock_auth_for_test.dart';

/// Oturumu var ama profili yok: uygulama kayıt ekranında açılır.
class _NewUserAuth extends MockAuthForTest {
  bool registered = false;

  @override
  bool get hasSession => true;

  @override
  Future<UserModel?> getCurrentUser() async =>
      registered ? super.getCurrentUser() : null;

  @override
  Future<UserModel> completeRegistration({
    required String fullName,
    required String username,
    required UserTitle title,
    String? bio,
    String? university,
    String? city,
    String? workplace,
    int? experienceYears,
    File? avatarFile,
  }) async {
    registered = true;
    return (await super.getCurrentUser())!;
  }
}

void main() {
  testWidgets(
      'kayıt sonrası başarı diyaloğu görünür, sonra feed açılır; hazır avatar yok '
      '(BUG-21, AUTH-8)', (tester) async {
    await pumpDentLink(tester, auth: _NewUserAuth());

    await tester.enterText(find.byType(TextField).first, 'Ayşe Yılmaz');
    await tester.tap(find.text('Öğrenci'));
    await tester.pumpAndSettle();

    // Koşullar onaylanmadan ilk adım geçilmez.
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(find.text('Devam etmek için kullanım koşullarını kabul etmelisin'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(find.text('veya bir avatar seçin'), findsNothing);

    await tester.tap(find.text('Profilimi Tamamla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kaydınız Tamamlandı!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Kaydınız Tamamlandı!'), findsNothing);
    expect(find.text(seedCase.title), findsOneWidget);
  });
}
