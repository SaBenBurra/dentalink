import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/profile/screens/followers_screen.dart';
import 'package:dentlink/providers/user_provider.dart';
import 'package:flutter/material.dart';

/// Postu beğenenler (`/post/:id/likes`).
class PostLikersScreen extends StatelessWidget {
  const PostLikersScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.likersTitle)),
      body: UserListView(
        provider: postLikersProvider(postId),
        emptyMessage: l10n.noLikersYet,
      ),
    );
  }
}
