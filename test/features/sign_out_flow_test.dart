import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/core/router/app_router.dart';
import 'package:dentigo/features/auth/screens/login_screen.dart';
import 'package:dentigo/features/settings/widgets/sign_out_dialog.dart';
import 'package:dentigo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/mock_auth_for_test.dart';

/// Supabase gibi: çıkış olayı yayınlanır, istek biraz sonra tamamlanır; router
/// diyalog hâlâ açıkken login'e yönlendirir.
class _SupabaseLikeAuth extends MockAuthForTest {
  @override
  Future<void> signOut() async {
    expireSession();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('ayarlardan çıkış login ekranına hatasız döner', (tester) async {
    await pumpDentigo(tester, auth: _SupabaseLikeAuth());
    ProviderScope.containerOf(
      tester.element(find.byType(MainApp)),
    ).read(routerProvider).push('/settings');
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('tr'));
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, l10n.settingsLogout),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.settingsLogout));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.settingsLogout));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignOutDialog), findsNothing);
  });
}
