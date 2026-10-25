import 'dart:io';

import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/features/post/screens/create_case_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../../integration_test/mock_auth_for_test.dart';

/// Galeri seçimi gerçek bir dosya döndürür (grid önizlemesi Image.file).
class _FakePicker extends ImagePickerPlatform {
  _FakePicker(this.path);
  final String path;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async =>
      [XFile(path)];
}

class _PostRepo implements ICreatePostRepository {
  int calls = 0;

  @override
  Future<PostModel> createCase({
    required String title,
    required String content,
    required DentalBranch branch,
    required List<File> imageFiles,
    required List<String> tags,
  }) async {
    calls++;
    throw const NetworkFailure(); // gönderimin kapıdan geçtiğini görmek yeterli
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 1x1 şeffaf PNG.
const _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

void main() {
  testWidgets('vaka: hasta mahremiyeti onayı olmadan gönderilmez', (tester) async {
    final dir = Directory.systemTemp.createTempSync('case_privacy');
    addTearDown(() => dir.deleteSync(recursive: true));
    final image = File('${dir.path}/x.png')..writeAsBytesSync(_png);
    ImagePickerPlatform.instance = _FakePicker(image.path);
    final repo = _PostRepo();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthForTest()),
        createPostRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CreateCaseScreen(),
      ),
    ));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Vaka başlığı');
    await tester.enterText(fields.at(1), 'Vaka açıklaması');
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endodonti').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.add_photo_alternate_outlined).first);
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeriden Seç'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paylaş'));
    await tester.pumpAndSettle();
    expect(find.text('Paylaşmadan önce hasta mahremiyeti onayını işaretlemelisin'),
        findsOneWidget);
    expect(repo.calls, 0);
    // Kullanıcı gibi uyarıyı kapat; floating SnackBar alttaki kutuyu örtebiliyor.
    ScaffoldMessenger.of(tester.element(find.byType(CreateCaseScreen))).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
    // compressToWebp gerçek dosya G/Ç yapar; sahte zaman bölgesinde tamamlanmaz.
    await tester.runAsync(() async {
      await tester.tap(find.text('Paylaş'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
  });
}
