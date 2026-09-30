import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.otherUser});

  final ChatUser otherUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();
    if (currentUser == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    try {
      await _chatService.sendMessage(
        senderId: currentUser.uid,
        receiverId: widget.otherUser.uid,
        text: text,
      );
    } catch (error) {
      if (!mounted) return;
      _messageController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Message was not sent: $error')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: SizedBox());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundImage: widget.otherUser.photoUrl.isEmpty
                  ? null
                  : NetworkImage(widget.otherUser.photoUrl),
              child: widget.otherUser.photoUrl.isEmpty
                  ? Text(
                      widget.otherUser.initials.isEmpty
                          ? '?'
                          : widget.otherUser.initials,
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.otherUser.email,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.messages(
                firstUserId: currentUser.uid,
                secondUserId: widget.otherUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _messageError(snapshot.error!);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markReceivedMessagesAsSeen(
                    firstUserId: currentUser.uid,
                    secondUserId: widget.otherUser.uid,
                    messages: messages,
                  );
                });
                if (messages.isEmpty) return _newConversationView();
                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 8.h),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _messageBubble(
                    context,
                    messages[index],
                    isMine: messages[index].senderId == currentUser.uid,
                  ),
                );
              },
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _messageBubble(
    BuildContext context,
    Message message, {
    required bool isMine,
  }) {
    final foreground = isMine
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final background = isMine
        ? const Color(0xFF123B7A)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      key: ValueKey('${message.id}-${message.status.name}'),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((isMine ? 24 : -24) * (1 - value), 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: 290.w),
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 12.w, 7.h),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isMine ? 18.r : 4.r),
              bottomRight: Radius.circular(isMine ? 4.r : 18.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(color: foreground, fontSize: 14.sp),
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _messageTime(context, message),
                    style: TextStyle(
                      color: foreground.withValues(alpha: .72),
                      fontSize: 10.sp,
                    ),
                  ),
                  if (isMine) ...[
                    SizedBox(width: 5.w),
                    _statusIndicator(message.status, foreground),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(MessageStatus status, Color foreground) {
    switch (status) {
      case MessageStatus.sending:
        return Text(
          'Sending…',
          style: TextStyle(
            color: foreground.withValues(alpha: .78),
            fontSize: 10.sp,
          ),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done,
          size: 15.sp,
          color: foreground.withValues(alpha: .82),
        );
      case MessageStatus.seen:
        return Icon(
          Icons.done_all,
          size: 16.sp,
          color: const Color(0xFF9EE9FF),
        );
    }
  }

  String _messageTime(BuildContext context, Message message) {
    if (message.sentAt == null) return 'Now';
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(message.sentAt!));
  }

  Widget _composer() => SafeArea(
    top: false,
    child: Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Write a message',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton.filled(
            tooltip: 'Send message',
            onPressed: _isSending ? null : _sendMessage,
            icon: _isSending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );

  Widget _newConversationView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forum_outlined, size: 52.sp),
        SizedBox(height: 12.h),
        Text('Start a conversation with ${widget.otherUser.displayName}.'),
      ],
    ),
  );

  Widget _messageError(Object error) => Center(
    child: Padding(
      padding: EdgeInsets.all(24.r),
      child: Text(
        'Unable to load messages. Check your Firestore rules.\n\n$error',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
