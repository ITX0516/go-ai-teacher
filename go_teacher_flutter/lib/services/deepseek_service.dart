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

  Future<String> explainMove(String move, int moveNumber, String context, String? gameSgf) async {
    const systemPrompt = '''你是一位资深的围棋AI老师，教学经验丰富，善于用通俗易懂的语言讲解围棋知识。
请针对学生的问题，给出专业但不晦涩的讲解，结合棋理和实战经验，帮助学生理解每一步棋的意图和价值。
讲解时注意：
1. 先直接回答问题，再展开分析
2. 结合具体的棋形和局面
3. 适当引用围棋谚语或口诀
4. 给出后续的学习建议
5. 语言亲切自然，像一位耐心的老师''';

    final userPrompt = '''请分析这步棋：
- 着点：$move
- 手数：第 $moveNumber 手
- 阶段：$context
- 当前局面：${gameSgf ?? '（暂无完整棋谱）'}

请从以下几个方面讲解：
1. 这步棋的意图是什么？
2. 这步棋的好坏评价
3. 有没有更好的选择？
4. 给学生的建议和提示''';

    return chat(systemPrompt, userPrompt);
  }

  Future<String> askQuestion(String question, String? gameSgf) async {
    const systemPrompt = '''你是一位资深的围棋AI老师，教学经验丰富，善于用通俗易懂的语言解答学生的各种围棋问题。
无论学生问的是规则、棋理、定式、死活、中盘战术还是官子知识，都能给出清晰准确的解答。
回答时注意：
1. 先直接回答问题
2. 再展开分析和举例
3. 语言通俗易懂，避免过于专业的术语，必要时解释术语
4. 适当引用围棋谚语帮助记忆
5. 鼓励学生，给出学习建议''';

    final userPrompt = '''学生的问题：$question
${gameSgf != null ? '当前棋局：$gameSgf' : ''}

请耐心解答学生的问题。''';

    return chat(systemPrompt, userPrompt);
  }

  Future<String> gameSummary(String sgf, String result) async {
    const systemPrompt = '''你是一位资深的围棋复盘老师，擅长从全局角度分析一局棋的得失，给出专业而中肯的评价和学习建议。
复盘总结要包含：整体评价、优点分析、需要改进的地方、学习建议四个部分。
语言要鼓励为主，同时指出真实存在的问题，帮助学生提高。''';

    final userPrompt = '''请对这局棋进行复盘总结：
- 棋谱：$sgf
- 结果：$result

请从以下方面进行总结：
1. 整体评价
2. 双方的优点
3. 需要改进的地方
4. 具体的学习建议''';

    return chat(systemPrompt, userPrompt);
  }
}
