import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  const ChatUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;

  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  factory ChatUser.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChatUser(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Unnamed user',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
    );
  }
}
