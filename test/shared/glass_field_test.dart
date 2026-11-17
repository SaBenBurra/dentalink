import 'package:dentigo/shared/widgets/glass_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget field(String? error) => MaterialApp(
    home: Scaffold(
      body: GlassField(
        controller: TextEditingController(),
        focusNode: FocusNode(),
        hintText: 'Ad Soyad',
        icon: Icons.person,
        errorText: error,
      ),
    ),
  );

  testWidgets('hata metni alanın altında görünür', (tester) async {
    await tester.pumpWidget(field('Ad gerekli'));
    expect(find.text('Ad gerekli'), findsOneWidget);

    await tester.pumpWidget(field(null));
    expect(find.text('Ad gerekli'), findsNothing);
  });
}
