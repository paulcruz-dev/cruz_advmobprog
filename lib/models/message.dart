import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, delivered, seen }

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.sentAt,
    required this.status,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime? sentAt;
  final MessageStatus status;

  factory Message.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final timestamp = data['sentAt'];
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: timestamp is Timestamp ? timestamp.toDate() : null,
      status: MessageStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => MessageStatus.delivered,
      ),
    );
  }
}
