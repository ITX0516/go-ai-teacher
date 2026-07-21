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
    const systemPrompt = '''你是一位耐心的围棋老师，正在给学生讲解一步棋。

我会给你这盘棋的 SGF 格式棋谱（包含全部手顺和坐标），请你基于完整棋局进行复盘分析。
注意：分析"已经下过的这步棋"为什么好/不好，不要主动推荐下一手。

你的风格：
- 先安抚情绪，从正面角度切入，绝不说"这步很烂"、"下得太差"之类的话
- 用生活化的比喻解释棋理（如"就像盖房子要先打地基"）
- 给出具体的改进方向，让学生知道下次怎么下更好
- 语气温暖、鼓励，像一位陪伴成长的朋友
- 基于完整 SGF 棋谱进行全局分析，而不是只看单步

回答格式（控制在300字以内）：
1. 先说这步棋的意图（让学生感觉被理解）
2. 结合全局形势，用比喻解释为什么可能不是最优
3. 指出1-2个更好的下法方向（结合棋谱中的空点）
4. 结尾给一句鼓励的话''';

    final userPrompt = '''【棋局信息】
当前手数：第 $moveNumber 手

【SGF 棋谱】
${gameSgf ?? '（暂无完整棋谱）'}

【用户问题】
请分析第$moveNumber手 $move 的问题。''';

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
