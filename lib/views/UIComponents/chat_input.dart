import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(bool) onTypingChanged;
  final VoidCallback onPlusButtonPressed;
  final VoidCallback onResetInactivityTimer;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    required this.onTypingChanged,
    required this.onPlusButtonPressed,
    required this.onResetInactivityTimer,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _messageController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4.0,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue[400],
                  size: 26,
                ),
                onPressed: () {
                  // Dismiss keyboard when opening drawer
                  FocusScope.of(context).unfocus();
                  // Reset inactivity timer on interaction
                  widget.onResetInactivityTimer();
                  widget.onPlusButtonPressed();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 16),
                        onChanged: (text) {
                          setState(() {}); // Rebuild to update send button color
                          if (text.isNotEmpty) {
                            widget.onTypingChanged(true);
                          } else {
                            widget.onTypingChanged(false);
                          }
                          // Reset inactivity timer when typing
                          widget.onResetInactivityTimer();
                        },
                        onSubmitted: (_) => widget.onResetInactivityTimer(),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: hasText ? Colors.blue[400] : Colors.grey[300],
                          size: 24,
                        ),
                        onPressed: hasText
                            ? () {
                                widget.onSendMessage(_messageController.text);
                                _messageController.clear();
                                // Reset inactivity timer
                                widget.onResetInactivityTimer();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 