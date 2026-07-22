import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  final String apiKey;
  final String baseUrl;
  final String model;

  DeepSeekService({
    required this.apiKey,
    this.baseUrl = 'https://api.deepseek.com',
    this.model = 'deepseek-chat',
  });

  /// 底层 API 调用：Prompt 裸奔（System 空、temperature 0.9、max_tokens 2000）
  Future<String> chatWithRawPrompt(
    String userMessage, {
    List<Map<String, String>> history = const [],
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': ''},
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.9,
        'max_tokens': 2000,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.toString() ?? '';
    } else {
      throw Exception('DeepSeek API Error: ${response.statusCode} - ${response.body}');
    }
  }

  /// 把 KataGo 数据拼成自然语言段落（不是 JSON）
  String _kataGoToText(Map<String, dynamic>? k) {
    if (k == null) return '';
    final sb = StringBuffer();
    final moveNumber = k['moveNumber'];
    if (moveNumber is int && moveNumber > 0) {
      sb.writeln('当前手数：第 $moveNumber 手');
    }
    final wr = (k['winrate'] as num?)?.toDouble();
    if (wr != null) {
      final blackWR = (wr * 100).toStringAsFixed(0);
      final whiteWR = (100 - wr * 100).toStringAsFixed(0);
      sb.writeln('胜率：黑 $blackWR% 白 $whiteWR%');
    }
    final wrChange = (k['winrateChange'] as num?)?.toDouble();
    if (wrChange != null && wrChange.abs() >= 0.0005) {
      final sign = wrChange > 0 ? '+' : '';
      sb.writeln('这手导致胜率变化：$sign${(wrChange * 100).toStringAsFixed(0)}%');
    }
    final bestMove = k['bestMove'] as String?;
    if (bestMove != null && bestMove.isNotEmpty) {
      sb.writeln('AI 推荐最佳一手：$bestMove');
    }
    final scoreLead = (k['scoreLead'] as num?)?.toDouble();
    if (scoreLead != null && scoreLead.abs() >= 0.05) {
      if (scoreLead > 0) {
        sb.writeln('目差：黑领先 ${scoreLead.toStringAsFixed(1)} 目');
      } else {
        sb.writeln('目差：白领先 ${(-scoreLead).toStringAsFixed(1)} 目');
      }
    }
    final currentPlayer = k['currentPlayer'] as String?;
    if (currentPlayer != null && currentPlayer.isNotEmpty) {
      sb.writeln('当前行棋方：$currentPlayer');
    }
    final candidates = k['candidateMoves'] as List?;
    if (candidates is List && candidates.isNotEmpty) {
      final parts = <String>[];
      final n = candidates.length < 3 ? candidates.length : 3;
      for (var i = 0; i < n; i++) {
        final cm = candidates[i];
        if (cm is Map) {
          final move = cm['move']?.toString() ?? '';
          final cwr = (cm['winrate'] as num?)?.toDouble() ?? 0;
          if (move.isNotEmpty) {
            parts.add('$move(${(cwr * 100).toStringAsFixed(0)}%)');
          }
        }
      }
      if (parts.isNotEmpty) {
        sb.writeln('候选点：${parts.join(' ')}');
      }
    }
    return sb.toString().trimRight();
  }

  Future<String> explainMove(
    String move,
    int moveNumber,
    double winRateChange,
    String? gameSgf, {
    Map<String, dynamic>? kataGoData,
  }) async {
    final sb = StringBuffer();
    if (gameSgf != null && gameSgf.isNotEmpty) {
      sb.writeln(gameSgf);
      sb.writeln();
    }
    final kataText = _kataGoToText(kataGoData);
    if (kataText.isNotEmpty) {
      sb.writeln(kataText);
      sb.writeln();
    }
    sb.write('第 $moveNumber 手 $move 走得怎么样？');
    return chatWithRawPrompt(sb.toString());
  }

  Future<String> askQuestion(
    String question,
    String? gameSgf, {
    Map<String, dynamic>? kataGoData,
    List<Map<String, String>> history = const [],
  }) async {
    final sb = StringBuffer();
    if (gameSgf != null && gameSgf.isNotEmpty) {
      sb.writeln(gameSgf);
      sb.writeln();
    }
    final kataText = _kataGoToText(kataGoData);
    if (kataText.isNotEmpty) {
      sb.writeln(kataText);
      sb.writeln();
    }
    sb.write(question);
    return chatWithRawPrompt(sb.toString(), history: history);
  }

  Future<String> gameSummary(String sgf, String result) async {
    final sb = StringBuffer();
    if (sgf.isNotEmpty) {
      sb.writeln(sgf);
      sb.writeln();
    }
    sb.writeln('本局结果：$result');
    sb.writeln();
    sb.write('请简短复盘这局棋，3-5 句话即可，说重点。');
    return chatWithRawPrompt(sb.toString());
  }
}
