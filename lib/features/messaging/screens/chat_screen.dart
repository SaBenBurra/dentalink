import 'package:flutter/material.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String avatarUrl;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Merhaba, vaka hakkındaki görüşleriniz nelerdir?',
      'isMe': false,
      'time': '14:30',
    },
    {
      'text':
          'Merhaba! Röntgeni inceledim, bence kanal tedavisi yeterli olacaktır.',
      'isMe': true,
      'time': '14:32',
    },
    {
      'text': 'Anladım. Peki ekstra bir restorasyon gerekir mi?',
      'isMe': false,
      'time': '14:35',
    },
    {
      'text':
          'Duruma göre kompozit veya kuron düşünülebilir. Hastanın durumu nasıl?',
      'isMe': true,
      'time': '14:36',
    },
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'text': text, 'isMe': true, 'time': '14:40'});
      });
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: widget.userName,
              imageUrl: widget.avatarUrl,
              size: AvatarSize.medium,
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacing16,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  text: message['text'],
                  isMe: message['isMe'],
                  time: message['time'],
                );
              },
            ),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onAttachment: () {},
          ),
        ],
      ),
    );
  }
}
