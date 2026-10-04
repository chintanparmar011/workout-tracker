class AiMessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final List<String>? quickFollowUps;

  AiMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.quickFollowUps,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'quickFollowUps': quickFollowUps,
    };
  }

  factory AiMessageModel.fromMap(Map<String, dynamic> map) {
    return AiMessageModel(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isError: map['isError'] ?? false,
      quickFollowUps: map['quickFollowUps'] != null
          ? List<String>.from(map['quickFollowUps'])
          : null,
    );
  }
}
