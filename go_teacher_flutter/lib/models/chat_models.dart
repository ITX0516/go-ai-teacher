/// 聊天消息角色
enum ChatRole {
  user,
  assistant,
  system,
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  String get roleName => role == ChatRole.user ? '你' : 'AI老师';

  Map<String, String> toHistoryJson() => {
        'role': role == ChatRole.user ? 'user' : 'assistant',
        'content': content,
      };

  factory ChatMessage.user(String content) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        role: ChatRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );
}
