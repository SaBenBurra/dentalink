import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/features/post/widgets/media_reorder_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;

void main() {
  testWidgets('basılı tutup sürükleyince medya sırası değişir', (tester) async {
    final items = ['a', 'b', 'c'];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MediaReorderStrip(
              onReorder: (oldIndex, newIndex) => setState(
                () => items.insert(newIndex, items.removeAt(oldIndex)),
              ),
              children: [
                for (final i in items)
                  MediaTile(key: ValueKey(i), child: Text(i)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('Sırayı değiştirmek için basılı tutup sürükleyin.'),
      findsOneWidget,
    );

    // İlk öğeyi en sona sürükle.
    final gesture = await tester.startGesture(tester.getCenter(find.text('a')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(items, ['b', 'c', 'a']);
  });
}
