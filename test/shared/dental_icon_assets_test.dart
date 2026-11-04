import 'dart:io';

import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/shared/extensions/dental_branch_ui.dart';
import 'package:dentigo/shared/extensions/user_title_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her branşın ikon dosyası var', () {
    for (final branch in DentalBranch.values) {
      expect(File(branch.iconAsset).existsSync(), isTrue, reason: '$branch');
    }
  });

  test('her unvanın ikon dosyası var', () {
    for (final title in UserTitle.values) {
      expect(File(title.iconAsset).existsSync(), isTrue, reason: '$title');
    }
  });
}
