import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../providers/following_provider.dart';
import '../../providers/user_provider.dart';
import '../utils/error_messages.dart';

/// Gerçek takip durumunu gösteren ve değiştiren buton.
///
/// `userProfileProvider` yüklenirken takip durumunu `followingStateProvider`'a
/// yazar; toggle aynı notifier üzerinden yapıldığı için takipçi sayısı da
/// iyimser güncellenir ve hata olursa geri alınır.
class FollowButton extends ConsumerStatefulWidget {
  final String userId;
  final ButtonStyle? style;

  const FollowButton({super.key, required this.userId, this.style});

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(userProfileProvider(widget.userId).notifier).toggleFollow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loaded = ref.watch(userProfileProvider(widget.userId)).hasValue;
    final isFollowing = ref.watch(isFollowingProvider(widget.userId));
    final onPressed = (_busy || !loaded) ? null : _toggle;

    return isFollowing
        ? OutlinedButton(
            onPressed: onPressed,
            style: widget.style,
            child: Text(l10n.unfollowButton),
          )
        : FilledButton(
            onPressed: onPressed,
            style: widget.style,
            child: Text(l10n.followButton),
          );
  }
}
