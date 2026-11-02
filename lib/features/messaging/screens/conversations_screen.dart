import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/user_search_delegate.dart';
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messagesTitle, style: textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.newMessage,
            icon: const Icon(Icons.add),
            onPressed: () async {
              final selectedUser = await showSearch(
                context: context,
                delegate: UserSearchDelegate(ref),
              );
              if (selectedUser != null && context.mounted) {
                context.pushNamed(
                  'chat',
                  pathParameters: {'userId': selectedUser.id},
                  queryParameters: {
                    'name': selectedUser.fullName,
                    'avatar': selectedUser.avatarUrl ?? '',
                  },
                );
              }
            },
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
              loading: () => const DentLinkLoadingSpinner(),
              error: (err, st) => DentLinkErrorWidget(
                message: l10n.conversationsLoadError,
                onRetry: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
              ),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return DentLinkEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l10n.noMessages,
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
                  return Center(child: Text(l10n.noResults));
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(conversationsProvider.future),
                  child: ListView.separated(
                    itemCount: filteredConversations.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
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
