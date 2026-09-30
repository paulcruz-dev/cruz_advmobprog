import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_user.dart';
import '../models/message.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ChatUser>> users() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map(ChatUser.fromDocument).toList();
      users.sort(
        (first, second) => first.displayName.toLowerCase().compareTo(
          second.displayName.toLowerCase(),
        ),
      );
      return users;
    });
  }

  String conversationIdFor(String firstUserId, String secondUserId) {
    final userIds = [firstUserId, secondUserId]..sort();
    return '${userIds.first}_${userIds.last}';
  }

  Stream<List<Message>> messages({
    required String firstUserId,
    required String secondUserId,
  }) {
    final conversationId = conversationIdFor(firstUserId, secondUserId);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Message.fromDocument)
              .where((message) => message.text.isNotEmpty)
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    final conversationId = conversationIdFor(senderId, receiverId);
    final conversation = _firestore
        .collection('conversations')
        .doc(conversationId);
    final message = conversation.collection('messages').doc();

    await conversation.set({
      'participantIds': [senderId, receiverId],
      'lastMessage': messageText,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await message.set({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': messageText,
      'sentAt': FieldValue.serverTimestamp(),
      'status': MessageStatus.sending.name,
    });

    // The first write lets the sender see a sending state before the message
    // transitions to delivered. A recipient opening the chat changes it to seen.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await message.update({'status': MessageStatus.delivered.name});
  }

  Future<void> markReceivedMessagesAsSeen({
    required String firstUserId,
    required String secondUserId,
    required List<Message> messages,
  }) async {
    final conversationId = conversationIdFor(firstUserId, secondUserId);
    final unread = messages.where(
      (message) =>
          message.receiverId == firstUserId &&
          message.status != MessageStatus.seen,
    );
    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final message in unread) {
      batch.update(
        _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(message.id),
        {'status': MessageStatus.seen.name},
      );
      hasUpdates = true;
    }
    if (hasUpdates) await batch.commit();
  }
}
