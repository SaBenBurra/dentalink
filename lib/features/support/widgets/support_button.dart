import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/support_provider.dart';

/// Destek ekibinin avatarı; personelin kendi fotoğrafı gösterilmez.
class SupportAvatar extends StatelessWidget {
  const SupportAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.support_agent_rounded,
        size: size * 0.55,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// Mesajlar ekranının sağ altındaki destek butonu; okunmamış cevapta rozet.
class SupportFab extends ConsumerWidget {
  const SupportFab({super.key, this.bottomInset = 0});

  /// Scaffold FAB'ın padding'ini siler; shell'in yüzen alt barı padding.bottom
  /// olarak verildiği için yükseklik Scaffold'ın dışında [insetOf] ile ölçülür.
  final double bottomInset;

  /// Scaffold FAB'ı zaten viewPadding (sistem çubuğu) kadar yukarı koyar; fark bar.
  static double insetOf(BuildContext context) {
    final inset =
        MediaQuery.paddingOf(context).bottom -
        MediaQuery.viewPaddingOf(context).bottom;
    return inset > 0 ? inset : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread =
        ref.watch(supportThreadProvider).valueOrNull?.hasUnread == true;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FloatingActionButton(
        heroTag: null,
        tooltip: AppLocalizations.of(context)!.supportContact,
        onPressed: () => context.push('/support'),
        child: Badge(
          isLabelVisible: hasUnread,
          child: const Icon(Icons.support_agent_rounded),
        ),
      ),
    );
  }
}
