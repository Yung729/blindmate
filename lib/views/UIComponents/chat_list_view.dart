import 'package:flutter/material.dart';
import 'package:blindmate/views/UIComponents/chat_bubble.dart';
import 'package:blindmate/views/UIComponents/typing_bubble.dart';
import 'package:blindmate/viewmodels/state/chat_state.dart';
import 'package:blindmate/views/UIComponents/trip_journal_card.dart';

class ChatListView extends StatelessWidget {
  final ChatState chatState;
  final String currentUserId;
  final String? currentUserAvatarImg;
  final bool isDrawerVisible;
  final double Function(BuildContext, bool) calculateDrawerHeight;
  final bool showStickers;

  const ChatListView({
    Key? key,
    required this.chatState,
    required this.currentUserId,
    this.currentUserAvatarImg,
    required this.isDrawerVisible,
    required this.calculateDrawerHeight,
    required this.showStickers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isDrawerVisible
              ? calculateDrawerHeight(context, showStickers)
              : 0,
        ),
        child: ListView.custom(
          reverse: true,
          childrenDelegate: SliverChildBuilderDelegate(
            (context, index) {
              if (chatState.isOtherUserTyping && index == 0) {
                return _buildTypingIndicatorBubble();
              }

              final messageIndex = chatState.isOtherUserTyping
                  ? index - 1
                  : index;
              final message = chatState.messages[messageIndex];
              final isMe = message.senderId == currentUserId;

              // Create a unique key based on the message ID
              final uniqueKey = message.messageId;
              return KeyedSubtree(
                key: ValueKey('message-$uniqueKey'),
                child: _buildChatBubble(
                  message,
                  isMe,
                ),
              );
            },
            // This preserves state across rebuilds
            findChildIndexCallback: (key) {
              final ValueKey<String> valueKey = key as ValueKey<String>;
              final String keyString = valueKey.value;

              // Skip for typing indicator
              if (keyString == 'typing-indicator') return null;

              // Extract unique message key from the key string
              final String messageUniqueKey = keyString.replaceFirst('message-', '');

              // Find the index of the message with this unique key
              final int messageIndex = chatState.messages.indexWhere(
                (m) => m.messageId == messageUniqueKey,
              );
              if (messageIndex < 0) return null;

              // Adjust for typing indicator if present
              return chatState.isOtherUserTyping
                  ? messageIndex + 1
                  : messageIndex;
            },
            childCount: chatState.messages.length +
                (chatState.isOtherUserTyping ? 1 : 0),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicatorBubble() {
    return KeyedSubtree(
      key: const ValueKey('typing-indicator'),
      child: ChatBubble(
        isMe: false,
        child: const TypingBubble(),
        showAvatar: true,
      ),
    );
  }

  Widget _buildChatBubble(message, bool isMe) {
    // Determine if this message should show avatar based on the next message
    final messageIndex = chatState.messages.indexOf(message);
    final nextMessage = messageIndex < chatState.messages.length - 1
        ? chatState.messages[messageIndex + 1]
        : null;

    // Show avatar if it's the last message from this sender
    final showAvatar = nextMessage == null || nextMessage.senderId != message.senderId;

  
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: ChatBubble(
        isMe: isMe,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        tripJournals: message.tripJournals,
        avatarUrl: isMe ? currentUserAvatarImg : chatState.otherUserAvatarImg,
        timestamp: message.timestamp,
        showAvatar: showAvatar,
        moderationStatus: message.moderationStatus,
      ),
    );
  }
} 