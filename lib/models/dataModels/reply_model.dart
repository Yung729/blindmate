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

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      replyId: json['replyId'],
      noteId: json['noteId'],
      responderId: json['responderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
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
