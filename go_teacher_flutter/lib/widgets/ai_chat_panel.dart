import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/game_service.dart';
import '../models/analysis_data.dart';
import 'chat_bubble.dart';

/// AI 老师聊天面板（DraggableScrollableSheet）
class AiChatPanel extends StatefulWidget {
  final String gameId;
  final String Function() getSgf;

  const AiChatPanel({
    super.key,
    required this.gameId,
    required this.getSgf,
  });

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _quickQuestions = [
    '分析当前局面',
    '这步有什么问题',
    '全局形势',
    '下一步推荐',
    '怎么收官',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();

    final chatService = context.read<ChatService>();
    chatService.addUserMessage(text);
    _scrollToBottom();

    chatService.setAiTyping(true);
    _scrollToBottom();

    try {
      final api = context.read<GameService>();
      final sgf = widget.getSgf();
      final history = chatService.getHistory();

      final answer = await api.chatWithHistory(
        widget.gameId,
        sgf,
        text,
        history,
      );
      chatService.addAssistantMessage(answer);
    } catch (e) {
      chatService.addAssistantMessage('抱歉，出错了：$e');
    } finally {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (context, chatService, _) {
        _scrollToBottom();
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(),
              const Divider(height: 1),
              // 聊天记录区
              Expanded(
                child: chatService.messages.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatService.messages.length + (chatService.isAiTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatService.messages.length && chatService.isAiTyping) {
                            return _buildTypingIndicator();
                          }
                          return ChatBubble(message: chatService.messages[index]);
                        },
                      ),
              ),
              const Divider(height: 1),
              // 快捷问题栏
              _buildQuickQuestions(),
              // 输入区
              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFBDBDBD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.school, color: Color(0xFF2D5016), size: 20),
          const SizedBox(width: 8),
          const Text(
            'AI 老师',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFF9E9E9E),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 48, color: Color(0xFFBDBDBD)),
          SizedBox(height: 12),
          Text(
            '向 AI 老师提问吧！',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            '点击下方快捷问题或直接输入',
            style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF2D5016),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
                SizedBox(width: 8),
                Text(
                  'AI老师正在输入...',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _quickQuestions.length,
        itemBuilder: (context, index) {
          final q = _quickQuestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(q, style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFFF5F5F5),
              side: BorderSide(color: const Color(0xFF2D5016).withValues(alpha: 0.2)),
              onPressed: () => _sendMessage(q),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 72),
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  decoration: InputDecoration(
                    hintText: '向 AI 老师提问...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF2D5016)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _sendMessage(_inputController.text),
              icon: const Icon(Icons.send, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 输入动画点
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller.drive(Tween(begin: 0.5, end: 1.0)),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF9E9E9E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
