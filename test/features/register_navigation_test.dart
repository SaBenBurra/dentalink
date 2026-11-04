import 'package:dentigo/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/mock_auth_for_test.dart';

class _NewUserAuth extends MockAuthForTest {
  @override
  bool get hasSession => true;

  @override
  Future<UserModel?> getCurrentUser() async => null;
}

Future<void> _toStepTwo(WidgetTester tester) async {
  await pumpDentigo(tester, auth: _NewUserAuth());
  await tester.enterText(find.byType(TextField).first, 'Ayşe Yılmaz');
  await tester.tap(find.text('Öğrenci'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(CheckboxListTile));
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Devam Et'));
  await tester.pumpAndSettle();
  expect(find.text('Adım 2 / 3'), findsWidgets);
}

void main() {
  testWidgets('başlıktaki Geç sonraki, geri önceki adıma gider', (
    tester,
  ) async {
    await _toStepTwo(tester);

    await tester.tap(find.text('Geç'));
    await tester.pumpAndSettle();
    expect(find.text('Adım 3 / 3'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Adım 2 / 3'), findsWidgets);
  });

  testWidgets('Android geri tuşu önceki adıma döner, uygulamadan çıkmaz', (
    tester,
  ) async {
    await _toStepTwo(tester);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('Adım 1 / 3'), findsWidgets);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
  });
}
