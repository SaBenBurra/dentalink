import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../data/models/post_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/listing_card.dart';

/// İlanın post sayfası: kart, satıcıya yaz (sahibine satıldı düğmesi) ve
/// "yalnızca barındırır" notu. Yorum yok; konuşma DM'de (052).
class ListingDetail extends ConsumerStatefulWidget {
  const ListingDetail({
    super.key,
    required this.post,
    required this.onBookmarkToggle,
    required this.onSoldChanged,
  });

  final ListingPostModel post;
  final VoidCallback onBookmarkToggle;
  final Future<void> Function(bool sold) onSoldChanged;

  @override
  ConsumerState<ListingDetail> createState() => _ListingDetailState();
}

class _ListingDetailState extends ConsumerState<ListingDetail> {
  bool _busy = false;

  Future<void> _toggleSold() async {
    setState(() => _busy = true);
    await widget.onSoldChanged(!widget.post.isSold);
    if (mounted) setState(() => _busy = false);
  }

  void _contactSeller() {
    final post = widget.post;
    context.push(
      Uri(
        path: '/chat/${post.userId}',
        queryParameters: {
          'name': post.author.fullName,
          'avatar': post.author.avatarUrl ?? '',
          'text': AppLocalizations.of(context)!.listingChatDraft(post.title),
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final post = widget.post;
    final isOwner = ref.watch(currentUserProvider)?.id == post.userId;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: AppDimensions.spacing8,
        bottom: AppDimensions.spacing16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        ListingCard(
          post: post,
          expanded: true,
          onBookmarkToggle: widget.onBookmarkToggle,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacing16,
            AppDimensions.spacing16,
            AppDimensions.spacing16,
            0,
          ),
          child: isOwner
              ? OutlinedButton.icon(
                  onPressed: _busy ? null : _toggleSold,
                  icon: Icon(
                    post.isSold ? Icons.replay : Icons.check_circle_outline,
                  ),
                  label: Text(
                    post.isSold
                        ? l10n.listingMarkAvailable
                        : l10n.listingMarkSold,
                  ),
                )
              // Satılan ilana yazılmaz: satıcıya mesaj gitmeye devam etmesin.
              : post.isSold
              ? const SizedBox.shrink()
              : FilledButton.icon(
                  onPressed: _contactSeller,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.listingContactSeller),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Text(
            l10n.listingDisclaimer,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
