import 'dart:math';

import 'package:dentigo/core/constants/app_colors.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/shared/extensions/dental_branch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  for (final (brightness, surface) in [
    (Brightness.light, AppColors.lightSurface),
    (Brightness.dark, AppColors.darkSurface),
  ]) {
    testWidgets('branş renkleri $brightness zeminde ≥ 4.5:1 ve farklı', (
      tester,
    ) async {
      late List<Color> colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(
            builder: (context) {
              colors = [
                for (final b in DentalBranch.values) b.colorOf(context),
              ];
              return const SizedBox();
            },
          ),
        ),
      );
      for (final (i, c) in colors.indexed) {
        expect(
          _contrast(c, surface),
          greaterThanOrEqualTo(4.5),
          reason: DentalBranch.values[i].name,
        );
      }
      expect(colors.toSet(), hasLength(DentalBranch.values.length));
    });
  }
}
