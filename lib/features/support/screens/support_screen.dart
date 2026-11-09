import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/support_model.dart';
import '../../../providers/support_provider.dart';
import '../../../shared/extensions/support_l10n.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../messaging/widgets/chat_input.dart';
import '../../messaging/widgets/message_bubble.dart';
import '../widgets/support_tile.dart';

final _timeFormatter = DateFormat('HH:mm');

/// Ardışık mesajlar aynı gönderenden, aynı gün ve 5 dakika içindeyse tek grup.
bool _sameGroup(SupportMessage? a, SupportMessage? b) =>
    a != null &&
    b != null &&
    a.fromStaff == b.fromStaff &&
    a.staffName == b.staffName &&
    DateUtils.isSameDay(a.createdAt, b.createdAt) &&
    b.createdAt.difference(a.createdAt).abs() < const Duration(minutes: 5);

/// Kullanıcının destek ekibiyle tek, sürekli sohbeti. Cevaplar admin panelinden gelir.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _controller = TextEditingController();
  SupportCategory? _category;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markRead() {
    ref
        .read(supportThreadProvider.notifier)
        .markRead()
        .catchError((Object e) => debugPrint('SupportScreen markRead: $e'));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(supportChatProvider.notifier)
          .send(text, category: _category);
      if (mounted) _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getErrorMessage(AppLocalizations.of(context)!, e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final threadAsync = ref.watch(supportThreadProvider);
    final thread = threadAsync.valueOrNull;
    final chat = ref.watch(supportChatProvider);

    // Ekran açıkken gelen cevaplar da okundu sayılır.
    ref.listen(supportThreadProvider, (_, next) {
      if (next.valueOrNull?.hasUnread == true) _markRead();
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Row(
          children: [
            const SupportAvatar(size: AppDimensions.avatarMedium),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.supportTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (thread != null)
                    Text(
                      thread.status.label(l10n),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: threadAsync.hasError && thread == null
                ? _error(l10n)
                : chat.when(
                    loading: () => const DentigoLoadingSpinner(),
                    error: (e, st) {
                      debugPrint('SupportScreen: $e\n$st');
                      return _error(l10n);
                    },
                    data: (messages) => messages.isEmpty
                        ? _Intro(text: l10n.supportIntro)
                        : _MessageList(
                            messages: messages,
                            note: supportNoteOf(thread, messages),
                          ),
                  ),
          ),
          // Kategori yalnızca sohbet hiç yokken sorulur.
          if (threadAsync.hasValue && thread == null)
            _CategoryPicker(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
          ChatInput(
            controller: _controller,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _error(AppLocalizations l10n) => DentigoErrorWidget(
    message: l10n.supportLoadError,
    onRetry: () => ref.invalidate(supportThreadProvider),
  );
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.note});

  final List<SupportMessage> messages;
  final SupportNote? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = messages.length;
    final hasNote = note != null;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
      itemCount: count + (hasNote ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasNote && index == 0) {
          return _NoteText(
            text: switch (note!) {
              SupportNote.received => l10n.supportReceived,
              SupportNote.seen => l10n.supportSeen,
              SupportNote.resolved => l10n.supportResolvedNote,
            },
          );
        }
        final position = count - 1 - (index - (hasNote ? 1 : 0));
        final m = messages[position];
        final prev = position > 0 ? messages[position - 1] : null;
        final next = position < count - 1 ? messages[position + 1] : null;
        return MessageBubble(
          key: ValueKey(m.id),
          text: m.content,
          isMe: !m.fromStaff,
          time: _timeFormatter.format(m.createdAt),
          isFirstInGroup: !_sameGroup(prev, m),
          isLastInGroup: !_sameGroup(m, next),
          label: m.fromStaff
              ? (m.staffName == null
                    ? l10n.supportTitle
                    : l10n.supportStaffLabel(m.staffName!))
              : null,
          avatar: const SupportAvatar(size: AppDimensions.avatarSmall),
        );
      },
    );
  }
}

class _NoteText extends StatelessWidget {
  const _NoteText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacing24,
        AppDimensions.spacing8,
        AppDimensions.spacing24,
        0,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SupportAvatar(size: AppDimensions.avatarXLarge),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelected});

  final SupportCategory? selected;
  final ValueChanged<SupportCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12),
      child: Row(
        children: [
          Text(
            l10n.supportCategoryPrompt,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (final c in SupportCategory.values) ...[
            const SizedBox(width: AppDimensions.spacing8),
            ChoiceChip(
              label: Text(c.label(l10n)),
              selected: selected == c,
              onSelected: (on) => onSelected(on ? c : null),
            ),
          ],
        ],
      ),
    );
  }
}
