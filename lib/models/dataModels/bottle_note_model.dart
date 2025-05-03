class BottleNote {
  final String noteId;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final DateTime expirationTime;
  final String status;
  final List<String> replyIds;

  BottleNote({
    required this.noteId,
    required this.content,
    required this.senderId,
    required this.timestamp,
    required this.expirationTime,
    required this.status,
    this.replyIds = const [],
  });

  factory BottleNote.fromJson(Map<String, dynamic> map) {
    return BottleNote(
      noteId: map['noteId'] ?? '',
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
      timestamp:
          map['timestamp'] != null
              ? DateTime.parse(map['timestamp'])
              : DateTime.now(),
      expirationTime:
          map['expirationTime'] != null
              ? DateTime.parse(map['expirationTime'])
              : DateTime.now().add(const Duration(hours: 24)),
      status: ['INACTIVE', 'ACTIVE', 'DELETED'].contains(map['status'])
          ? map['status']
          : 'ACTIVE',
      replyIds: map['replies'] != null ? List<String>.from(map['replies']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'content': content,
    'senderId': senderId,
    'timestamp': timestamp.toIso8601String(),
    'expirationTime': expirationTime.toIso8601String(),
    'status': status,
    'replies': replyIds,
  };
}
