import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String? text;
  final String? stickerUrl;
  final Widget? child;

  const ChatBubble({
    Key? key,
    required this.isMe,
    this.text,
    this.stickerUrl,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/default_pic.jpg'),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blueAccent : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child:
                  child ??
                  (stickerUrl != null
                      ? Image.network(stickerUrl!, height: 100)
                      : Text(
                        text ?? "",
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      )),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/default_pic.jpg'),
            ),
        ],
      ),
    );
  }
}
