import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';

/// 聊天状态管理（ChangeNotifier）
/// 用于在 Tab 切换、面板收起/展开时保留聊天记录
class ChatService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  int _unreadAnalysisCount = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isAiTyping => _isAiTyping;
  int get unreadAnalysisCount => _unreadAnalysisCount;

  /// 添加用户消息
  void addUserMessage(String content) {
    _messages.add(ChatMessage.user(content));
    notifyListeners();
  }

  /// 添加 AI 消息
  void addAssistantMessage(String content) {
    _messages.add(ChatMessage.assistant(content));
    _isAiTyping = false;
    notifyListeners();
  }

  /// 设置 AI 正在输入状态
  void setAiTyping(bool typing) {
    _isAiTyping = typing;
    notifyListeners();
  }

  /// 增加未读分析数
  void incrementAnalysisCount() {
    _unreadAnalysisCount++;
    notifyListeners();
  }

  /// 清除未读分析数
  void clearAnalysisCount() {
    _unreadAnalysisCount = 0;
    notifyListeners();
  }

  /// 清空聊天记录
  void clear() {
    _messages.clear();
    _isAiTyping = false;
    notifyListeners();
  }

  /// 获取历史记录（用于 API 请求）
  List<Map<String, String>> getHistory() {
    return _messages.map((m) => m.toHistoryJson()).toList();
  }
}
