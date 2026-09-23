import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/user_search_delegate.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../../providers/message_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/relative_time_text.dart';
import '../../../core/l10n/generated/app_localizations.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesajlar', style: textTheme.titleLarge),
        actions: [
          IconButton(
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
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing8,
            ),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Mesajlarda ara...',
              leading: const Icon(Icons.search),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerHighest,
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: conversationsAsync.when(
              loading: () => const DentLinkLoadingSpinner(),
              error: (err, st) => DentLinkErrorWidget(
                message: 'Konuşmalar yüklenemedi',
                onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
              ),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const Center(child: Text('Henüz mesaj yok.'));
                }

                // Arama Filtresi
                final filteredConversations = conversations.where((c) {
                  if (_searchController.text.isNotEmpty) {
                    return c.otherUser.fullName
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());
                  }
                  return true;
                }).toList();
                
                if (filteredConversations.isEmpty) {
                  return const Center(child: Text('Sonuç bulunamadı.'));
                }

                return ListView.separated(
                  itemCount: filteredConversations.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 88),
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];

                    final timeStr = conversation.lastMessageAt != null
                        ? RelativeTimeText.format(
                            conversation.lastMessageAt!, l10n)
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
                          pathParameters: {'userId': conversation.otherUser.id},
                          queryParameters: {
                            'name': conversation.otherUser.fullName,
                            'avatar': conversation.otherUser.avatarUrl ?? '',
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
