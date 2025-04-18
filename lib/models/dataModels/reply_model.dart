class Reply {
  final String replyId;
  final String noteId;
  final String responderId;
  final String content;
  final DateTime timestamp;

  Reply({
    required this.replyId,
    required this.noteId,
    required this.responderId,
    required this.content,
    required this.timestamp,
  });

  factory Reply.fromJson(Map<String, dynamic> map) {
    return Reply(
      replyId: map['replyId'] ?? '',
      noteId: map['noteId'] ?? '',
      responderId: map['responderId'] ?? '',
      content: map['content'] ?? '',
      timestamp:
          map['timestamp'] != null
              ? DateTime.parse(map['timestamp'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'replyId': replyId,
    'noteId': noteId,
    'responderId': responderId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };
}
