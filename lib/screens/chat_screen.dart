import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/chat_user.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return _signedOutView(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatUser>>(
            stream: _chatService.users(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _errorView(context, snapshot.error!);
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data!
                  .where((user) => user.uid != currentUser.uid)
                  .where(_matchesSearch)
                  .toList();
              if (users.isEmpty) return _emptyView(context);
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                itemCount: users.length,
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
                itemBuilder: (context, index) =>
                    _userTile(context, users[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesSearch(ChatUser user) {
    if (_query.isEmpty) return true;
    return user.displayName.toLowerCase().contains(_query) ||
        user.email.toLowerCase().contains(_query);
  }

  Widget _userTile(BuildContext context, ChatUser user) {
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundImage: user.photoUrl.isEmpty
              ? null
              : NetworkImage(user.photoUrl),
          child: user.photoUrl.isEmpty
              ? Text(user.initials.isEmpty ? '?' : user.initials)
              : null,
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailScreen(otherUser: user)),
        ),
      ),
    );
  }

  Widget _signedOutView(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(28.r),
      child: const Text(
        'Chat is available for Firebase accounts. Sign in with Firebase to see registered users.',
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _emptyView(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(28.r),
      child: Text(
        _query.isEmpty
            ? 'No other Firebase users are registered yet. Create a second test account to begin chatting.'
            : 'No users match “$_query”.',
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _errorView(BuildContext context, Object error) => Center(
    child: Padding(
      padding: EdgeInsets.all(28.r),
      child: Text(
        'Unable to load chat users. Check your Firestore rules.\n\n$error',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
