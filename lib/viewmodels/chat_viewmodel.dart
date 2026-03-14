import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A single chat message.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) => ChatMessage(
        id: id,
        senderId: m['senderId'] ?? '',
        text: m['text'] ?? '',
        timestamp: m['timestamp'] is Timestamp
            ? (m['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
      );
}

/// Summary of a conversation shown in the list.
class ChatConversation {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastTimestamp;
  final String productTitle;

  ChatConversation({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.productTitle,
  });
}

class ChatViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Get or create a chat room between two users for a product ─────────
  Future<String> getOrCreateChat({
    required String sellerId,
    required String sellerName,
    required String productId,
    required String productTitle,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    // Chat ID = sorted user IDs + product ID → deterministic
    final parts = [uid, sellerId]..sort();
    final chatId = '${parts[0]}_${parts[1]}_$productId';

    final chatRef = _db.collection('chats').doc(chatId);
    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        'participants': [uid, sellerId],
        'productId': productId,
        'productTitle': productTitle,
        'participantNames': {
          uid: _auth.currentUser?.email ?? 'User',
          sellerId: sellerName,
        },
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  // ── Stream of conversations for current user ──────────────────────────
  Stream<List<ChatConversation>> getConversations() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final d = doc.data();
        final participants = List<String>.from(d['participants'] ?? []);
        final otherId = participants.firstWhere((p) => p != uid, orElse: () => '');
        final names = Map<String, dynamic>.from(d['participantNames'] ?? {});
        return ChatConversation(
          chatId: doc.id,
          otherUserId: otherId,
          otherUserName: (names[otherId] ?? 'Пользователь').toString(),
          lastMessage: d['lastMessage'] ?? '',
          lastTimestamp: d['lastTimestamp'] is Timestamp
              ? (d['lastTimestamp'] as Timestamp).toDate()
              : DateTime.now(),
          productTitle: d['productTitle'] ?? '',
        );
      }).toList();
      
      // Sort descending by timestamp on client to avoid composite index requirement
      list.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
      return list;
    });
  }

  // ── Stream of messages in a chat room ─────────────────────────────────
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  // ── Send a message ────────────────────────────────────────────────────
  Future<void> sendMessage(String chatId, String text) async {
    final uid = _uid;
    if (uid == null || text.trim().isEmpty) return;

    final batch = _db.batch();

    // Add message
    final msgRef =
        _db.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update chat summary
    final chatRef = _db.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastTimestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    notifyListeners();
  }
}
