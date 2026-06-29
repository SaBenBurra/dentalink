import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/conversation_tile.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock veri
  final List<Map<String, dynamic>> _mockConversations = [
    {
      'name': 'Dr. Aras Bulut',
      'lastMessage': 'Vaka hakkındaki görüşleriniz nelerdir?',
      'time': '14:30',
      'unreadCount': 2,
      'avatarUrl': 'https://i.pravatar.cc/150?u=1',
    },
    {
      'name': 'Dr. Selin Demir',
      'lastMessage': 'Tamam, teşekkür ederim. Sonra görüşürüz.',
      'time': '11:15',
      'unreadCount': 0,
      'avatarUrl': 'https://i.pravatar.cc/150?u=2',
    },
    {
      'name': 'Dt. Mehmet Yılmaz',
      'lastMessage': 'Panoramik röntgeni incelediniz mi?',
      'time': 'Dün',
      'unreadCount': 5,
      'avatarUrl': 'https://i.pravatar.cc/150?u=3',
    },
    {
      'name': 'Dr. Ayşe Kaya',
      'lastMessage': 'Yarın sabahki ameliyat için hazır mıyız?',
      'time': 'Pazartesi',
      'unreadCount': 0,
      'avatarUrl': 'https://i.pravatar.cc/150?u=4',
    },
    {
      'name': 'Prof. Dr. Ahmet Yılmaz',
      'lastMessage': 'Sunum dosyasını mail attım.',
      'time': 'Pazar',
      'unreadCount': 0,
      'avatarUrl': 'https://i.pravatar.cc/150?u=5',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesajlar', style: textTheme.titleLarge),
        actions: [
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
            child: ListView.separated(
              itemCount: _mockConversations.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 88),
              itemBuilder: (context, index) {
                final conversation = _mockConversations[index];

                // Basit arama filtresi
                if (_searchController.text.isNotEmpty &&
                    !conversation['name'].toString().toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    )) {
                  return const SizedBox.shrink();
                }

                return ConversationTile(
                  name: conversation['name'],
                  lastMessage: conversation['lastMessage'],
                  time: conversation['time'],
                  unreadCount: conversation['unreadCount'],
                  avatarUrl: conversation['avatarUrl'],
                  onTap: () {
                    context.pushNamed(
                      'chat',
                      pathParameters: {'userId': 'user_$index'},
                      queryParameters: {
                        'name': conversation['name'].toString(),
                        'avatar': conversation['avatarUrl'].toString(),
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
