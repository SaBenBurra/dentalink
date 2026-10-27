import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/enums.dart';
import '../../data/providers/repository_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/search_provider.dart';
import 'error_messages.dart';

/// Raporlama sheet'ini açar (post, yorum veya kullanıcı).
Future<void> showReportSheet(
  BuildContext context,
  ReportTarget target,
  String targetId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXLarge),
      ),
    ),
    builder: (_) => ReportSheet(target: target, targetId: targetId),
  );
}

/// Onay ister, kullanıcıyı engeller ve yazarın içeriğini yüklü listelerden
/// çıkarır. [postId] verilirse o postun yorumlarından da çıkarır.
/// Engellendiyse true döner.
Future<bool> confirmAndBlockUser(
  BuildContext context,
  WidgetRef ref,
  String userId, {
  String? postId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.blockConfirmTitle),
      content: Text(l10n.blockConfirmBody),
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
          child: Text(l10n.blockUser),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await ref.read(moderationRepositoryProvider).blockUser(userId);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
    return false;
  }
  if (ref.exists(feedProvider)) {
    ref.read(feedProvider.notifier).removeAuthor(userId);
  }
  if (ref.exists(searchProvider)) {
    ref.read(searchProvider.notifier).removeAuthor(userId);
  }
  if (postId != null && ref.exists(commentsProvider(postId))) {
    ref.read(commentsProvider(postId).notifier).removeAuthor(userId);
  }
  // Açık yanıt listeleri tek tek bilinmiyor; RLS engelliyi gizleyerek yeniden çeker.
  ref.invalidate(repliesProvider);
  ref.invalidate(authProvider); // takip sayıları DB'de düştü
  messenger.showSnackBar(SnackBar(content: Text(l10n.userBlocked)));
  return true;
}

/// Başka bir kullanıcıya ait içerik için ⋮ menüsü: Raporla + Engelle.
class ModerationMenuButton extends ConsumerWidget {
  const ModerationMenuButton({
    super.key,
    required this.target,
    required this.targetId,
    required this.userId,
    this.postId,
    this.onBlocked,
  });

  final ReportTarget target;
  final String targetId;
  final String userId;

  /// Yorum menüsünde: engellenince o postun yorumlarından da çıkar.
  final String? postId;
  final VoidCallback? onBlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<PostMenuAction>(
      tooltip: l10n.moreOptions,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        if (action == PostMenuAction.report) {
          await showReportSheet(context, target, targetId);
        } else if (action == PostMenuAction.block) {
          final blocked =
              await confirmAndBlockUser(context, ref, userId, postId: postId);
          if (blocked) onBlocked?.call();
        }
      },
      itemBuilder: (context) => moderationMenuItems(context),
    );
  }
}

/// Raporla ve Engelle menü öğeleri (post menüsü de kullanır).
List<PopupMenuEntry<PostMenuAction>> moderationMenuItems(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final error = Theme.of(context).colorScheme.error;
  return [
    PopupMenuItem(
      value: PostMenuAction.report,
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, size: 20),
          const SizedBox(width: AppDimensions.spacing8),
          Text(l10n.report),
        ],
      ),
    ),
    PopupMenuItem(
      value: PostMenuAction.block,
      child: Row(
        children: [
          Icon(Icons.block_outlined, size: 20, color: error),
          const SizedBox(width: AppDimensions.spacing8),
          Text(l10n.blockUser, style: TextStyle(color: error)),
        ],
      ),
    ),
  ];
}

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({super.key, required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  static const noteMaxLength = 500; // reports.note CHECK (023)

  final _note = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(moderationRepositoryProvider).report(
            widget.target,
            widget.targetId,
            reason,
            note: _note.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(l10n.reportSent)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.spacing16,
          right: AppDimensions.spacing16,
          top: AppDimensions.spacing16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spacing16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.reportTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppDimensions.spacing8),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (r) => setState(() => _reason = r),
                child: Column(
                  children: [
                    for (final r in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: r,
                        title: Text(reportReasonLabel(l10n, r)),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _note,
                maxLength: noteMaxLength,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(hintText: l10n.reportNoteHint),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              FilledButton(
                onPressed: _reason == null || _sending ? null : _submit,
                child: _sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.reportSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String reportReasonLabel(AppLocalizations l10n, ReportReason reason) =>
    switch (reason) {
      ReportReason.spam => l10n.reportReasonSpam,
      ReportReason.harassment => l10n.reportReasonHarassment,
      ReportReason.patientPrivacy => l10n.reportReasonPatientPrivacy,
      ReportReason.misinformation => l10n.reportReasonMisinformation,
      ReportReason.inappropriate => l10n.reportReasonInappropriate,
      ReportReason.other => l10n.reportReasonOther,
    };
