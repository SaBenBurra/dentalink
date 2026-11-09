import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/user_search_delegate.dart';
import '../../support/widgets/support_button.dart';
import '../../search/widgets/search_bar.dart';
import '../../../providers/message_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import 'chat_screen.dart' show chatListTime;
import '../../../core/l10n/generated/app_localizations.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startNewMessage() async {
    final selectedUser = await showSearch(
      context: context,
      delegate: UserSearchDelegate(ref),
    );
    if (selectedUser != null && mounted) {
      context.pushNamed(
        'chat',
        pathParameters: {'userId': selectedUser.id},
        queryParameters: {
          'name': selectedUser.fullName,
          'avatar': selectedUser.avatarUrl ?? '',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      floatingActionButton: SupportFab(
        bottomInset: SupportFab.insetOf(context),
      ),
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          l10n.messagesTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l10n.newMessage,
            color: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.edit_square),
            onPressed: _startNewMessage,
          ),
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: l10n.messagesSearchHint,
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: conversationsAsync.when(
              loading: () => const DentigoLoadingSpinner(),
              error: (err, st) => DentigoErrorWidget(
                message: l10n.conversationsLoadError,
                onRetry: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
              ),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return DentigoEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l10n.noMessages,
                    actionLabel: l10n.newMessage,
                    onAction: _startNewMessage,
                  );
                }

                // Arama Filtresi
                final filteredConversations = conversations.where((c) {
                  if (_searchController.text.isNotEmpty) {
                    return c.otherUser.fullName.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    );
                  }
                  return true;
                }).toList();

                if (filteredConversations.isEmpty) {
                  return DentigoEmptyState(
                    icon: Icons.search_off_rounded,
                    title: l10n.noResults,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(conversationsProvider.future),
                  child: ListView.builder(
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];

                      final timeStr = conversation.lastMessageAt != null
                          ? chatListTime(
                              conversation.lastMessageAt!,
                              DateTime.now(),
                              l10n,
                            )
                          : '';

                      return ConversationTile(
                        name: conversation.otherUser.fullName,
                        lastMessage: conversation.lastMessagePreview ?? '',
                        time: timeStr,
                        unreadCount: conversation.unreadCount,
                        avatarUrl: conversation.otherUser.avatarUrl ?? '',
                        onTap: () {
                          context.pushNamed(
                            'chat',
                            pathParameters: {
                              'userId': conversation.otherUser.id,
                            },
                            queryParameters: {
                              'name': conversation.otherUser.fullName,
                              'avatar': conversation.otherUser.avatarUrl ?? '',
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
