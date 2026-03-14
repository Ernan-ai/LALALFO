import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'auth_view.dart';
import 'chat_room_view.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (!auth.isLoggedIn) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 64, color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 14),
              Text('Войдите, чтобы видеть чаты',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.35))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AuthView())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AAFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Войти'),
              ),
            ],
          ),
        ),
      );
    }

    final chatVm = context.read<ChatViewModel>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: const Text('Чаты',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))
                .animate()
                .fadeIn(duration: 300.ms),
          ),
          Expanded(
            child: StreamBuilder<List<ChatConversation>>(
              stream: chatVm.getConversations(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00AAFF), strokeWidth: 2));
                }
                final chats = snap.data ?? [];
                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/faces/face4.jpg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .rotate(begin: -0.05, end: 0.05, duration: 1200.ms),
                        const SizedBox(height: 12),
                        Text('Нет сообщений',
                            style: TextStyle(
                                fontSize: 15,
                                color:
                                    Colors.white.withValues(alpha: 0.35))),
                        const SizedBox(height: 6),
                        Text('Напишите продавцу из объявления',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.white.withValues(alpha: 0.2))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: chats.length,
                  itemBuilder: (_, i) =>
                      _ConversationTile(conversation: chats[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  const _ConversationTile({required this.conversation});

  static const _faces = [
    'assets/faces/face1.jpg',
    'assets/faces/face2.jpg',
    'assets/faces/face3.jpg',
    'assets/faces/face4.jpg',
    'assets/faces/face5.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    // Deterministic face per conversation
    final faceIndex = conversation.chatId.hashCode.abs() % _faces.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomView(
              chatId: conversation.chatId,
              otherUserName: conversation.otherUserName,
              productTitle: conversation.productTitle,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // Funny face avatar!
            ClipOval(
              child: Image.asset(
                _faces[faceIndex],
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                      Text(
                        timeago.format(conversation.lastTimestamp,
                            locale: 'ru'),
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.white.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF00AAFF)
                            .withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage.isNotEmpty
                        ? conversation.lastMessage
                        : 'Начните общение',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

