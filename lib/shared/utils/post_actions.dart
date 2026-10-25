import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../data/providers/repository_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/post_provider.dart';
import 'error_messages.dart';

/// Yeni post oluşunca yenilenmesi gereken her şey: feed, profil sekmesi ve
/// post sayısı (authProvider). Yeni post ilk sayfada görünür.
void invalidateMyPosts(WidgetRef ref) {
  ref.invalidate(feedProvider);
  final uid = ref.read(currentUserProvider)?.id;
  if (uid != null) ref.invalidate(userPostsProvider(uid));
  ref.invalidate(authProvider);
}

/// Silinen post listelerden çıkar; yüklenen sayfalar yeniden çekilmez.
void _removeMyPost(WidgetRef ref, String postId) {
  if (ref.exists(feedProvider)) {
    ref.read(feedProvider.notifier).removePost(postId);
  }
  final uid = ref.read(currentUserProvider)?.id;
  if (uid != null && ref.exists(userPostsProvider(uid))) {
    ref.read(userPostsProvider(uid).notifier).removePost(postId);
  }
  ref.invalidate(authProvider);
}

/// Onay ister, gönderiyi siler ve listeleri yeniler. Silindiyse true döner.
Future<bool> confirmAndDeletePost(
  BuildContext context,
  WidgetRef ref,
  String postId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.postDeleteTitle),
      content: Text(l10n.postDeleteConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await ref.read(createPostRepositoryProvider).deletePost(postId);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
    return false;
  }
  _removeMyPost(ref, postId);
  messenger.showSnackBar(SnackBar(content: Text(l10n.postDeleted)));
  return true;
}
