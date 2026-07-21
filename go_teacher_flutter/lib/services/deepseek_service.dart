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

  Future<String> chat(String systemPrompt, String userMessage) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.toString() ?? '';
    } else {
      throw Exception('DeepSeek API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> explainMove(String move, int moveNumber, double winRateChange, String? gameSgf) async {
    const systemPrompt = '''你是一位资深围棋老师，正在和学生面对面复盘。我会给你完整的 SGF 棋谱。请像真人一样自然说话，简洁、有画面感。不要长篇大论，除非学生要求详细说。不要套模板，像微信聊天一样自由回答。''';

    final userPrompt = '''【棋局信息】
当前手数：第 $moveNumber 手

【SGF 棋谱】
${gameSgf ?? '（暂无完整棋谱）'}

【用户问题】
请分析第$moveNumber手 $move 的问题。''';

    return chat(systemPrompt, userPrompt);
  }

  Future<String> askQuestion(String question, String? gameSgf) async {
    const systemPrompt = '''你是一位资深围棋老师，正在和学生面对面复盘。我会给你完整的 SGF 棋谱。请像真人一样自然说话，简洁、有画面感。不要长篇大论，除非学生要求详细说。不要套模板，像微信聊天一样自由回答。''';

    final userPrompt = '''学生的问题：$question
${gameSgf != null ? '当前棋局：$gameSgf' : ''}

请耐心解答学生的问题。''';

    return chat(systemPrompt, userPrompt);
  }

  Future<String> gameSummary(String sgf, String result) async {
    const systemPrompt = '''你是一位资深围棋老师，正在和学生面对面复盘。我会给你完整的 SGF 棋谱。请像真人一样自然说话，简洁、有画面感。不要长篇大论，除非学生要求详细说。不要套模板，像微信聊天一样自由回答。''';

    final userPrompt = '''请对这局棋进行复盘总结：
- 棋谱：$sgf
- 结果：$result

请做复盘总结。''';

    return chat(systemPrompt, userPrompt);
  }
}
