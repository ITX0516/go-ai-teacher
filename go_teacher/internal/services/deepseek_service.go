package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"go_teacher/internal/models"
	"io"
	"net/http"
)

// 提示词模板1：错手分析 - 安抚情绪+通俗比喻+改进建议
const systemPromptExplainMove = `你是一位耐心的围棋老师，正在给学生讲解一步棋。

你的风格：
- 先安抚情绪，从正面角度切入，绝不说"这步很烂"、"下得太差"之类的话
- 用生活化的比喻解释棋理（如"就像盖房子要先打地基"）
- 给出具体的改进方向，让学生知道下次怎么下更好
- 语气温暖、鼓励，像一位陪伴成长的朋友

回答格式（控制在200字以内）：
1. 先说这步棋的意图（让学生感觉被理解）
2. 用比喻解释为什么可能不是最优
3. 指出1-2个更好的下法方向
4. 结尾给一句鼓励的话`

// 提示词模板2：形势判断 - 生活化比喻+要点提示
const systemPromptExplainPosition = `你是一位围棋老师，正在帮学生判断当前局面形势。

你的风格：
- 用生活化的比喻描述形势（如"你现在像在爬坡，有点累但风景不错"）
- 避免堆砌专业术语，用学生能懂的话解释
- 指出双方的要点和急所（用坐标说明，如"黑棋在D4位有个大场"）
- 给出1-2个具体可行的建议

回答格式（控制在250字以内）：
1. 用比喻描述当前形势
2. 指出双方的要点（各说1-2个）
3. 给出下一步的具体建议
4. 鼓励学生继续保持思考`

// 提示词模板3：复盘总结 - 亮点+改进+鼓励
const systemPromptAnalyzeSummary = `你是一位围棋老师，正在帮学生复盘整局棋。

你的风格：
- 整体评价要客观，但要有温度和鼓励
- 具体指出好棋和问题棋（用手数和坐标说明）
- 让学生感觉到进步的空间，而不是被批评
- 结尾给一句暖心的话，让学生愿意继续学

回答格式（控制在300字以内）：
1. 整体评价一句话（如"这盘棋你展现了不错的攻防意识"）
2. 3个亮点：具体手数+为什么好（用通俗话解释）
3. 2个改进点：具体手数+怎么改更好
4. 结尾一句鼓励的话（如"继续加油，你的棋力在稳步提升！"）`

type DeepSeekService struct {
	apiKey string
	apiURL string
	client *http.Client
}

func NewDeepSeekService(apiKey, apiURL string) *DeepSeekService {
	return &DeepSeekService{
		apiKey: apiKey,
		apiURL: apiURL,
		client: &http.Client{},
	}
}

type deepseekMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type deepseekRequest struct {
	Model    string        `json:"model"`
	Messages []deepseekMessage `json:"messages"`
	Stream   bool          `json:"stream"`
}

type deepseekResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

func (s *DeepSeekService) ExplainMove(move string, moveNumber int, winRateChange float64, gameContext string) (*models.Explanation, error) {
	userPrompt := fmt.Sprintf(`请讲解这步棋：
- 第 %d 手，落子位置：%s
- 胜率变化：%+.1f%%
- 局面描述：%s

请用通俗语言讲解，先说意图，再指出更好的下法。`, moveNumber, move, winRateChange, gameContext)

	response, err := s.chat(systemPromptExplainMove, userPrompt)
	if err != nil {
		return nil, err
	}

	level := "good"
	if winRateChange < -5 {
		level = "bad"
	} else if winRateChange < -2 {
		level = "doubtful"
	} else if winRateChange > 2 {
		level = "excellent"
	}

	return &models.Explanation{
		Move:        move,
		Explanation: response,
		Level:       level,
	}, nil
}

func (s *DeepSeekService) ExplainPosition(gameSGF string, userQuestion string) (string, error) {
	userPrompt := fmt.Sprintf(`当前棋局SGF棋谱：
%s

用户问题：%s

请用通俗语言判断形势，指出双方要点。`, gameSGF, userQuestion)

	return s.chat(systemPromptExplainPosition, userPrompt)
}

func (s *DeepSeekService) AnalyzeGameSummary(sgf string, result string) (string, error) {
	userPrompt := fmt.Sprintf(`棋谱SGF：
%s

结果：%s

请做复盘总结：整体评价+3个亮点+2个改进点+鼓励。`, sgf, result)

	return s.chat(systemPromptAnalyzeSummary, userPrompt)
}

func (s *DeepSeekService) GeneratePuzzleExplanation(puzzle *models.Puzzle, isCorrect bool, userMove string) (string, error) {
	systemPrompt := `你是一位耐心的围棋死活题老师，正在讲解一道题目。

你的风格：
- 先肯定学生的思考过程，再指出问题
- 用通俗语言解释棋理，避免术语堆砌
- 给出具体的解题思路和关键点
- 结尾鼓励学生继续努力`

	userPrompt := fmt.Sprintf(`题目：%s
难度：%s
描述：%s
正确答案序列：%v

用户走了：%s
是否正确：%v

请讲解这道题：先说用户这步棋的问题或亮点，再讲解正确思路。`, puzzle.Title, puzzle.Difficulty, puzzle.Description, puzzle.CorrectMoves, userMove, isCorrect)

	return s.chat(systemPrompt, userPrompt)
}

func (s *DeepSeekService) chat(systemPrompt, userMessage string) (string, error) {
	if s.apiKey == "" {
		return s.mockResponse(userMessage), nil
	}

	reqBody := deepseekRequest{
		Model:  "deepseek-chat",
		Stream: false,
		Messages: []deepseekMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userMessage},
		},
	}

	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", s.apiURL, bytes.NewReader(bodyBytes))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.apiKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	var result deepseekResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	if result.Error != nil {
		return "", fmt.Errorf("api error: %s", result.Error.Message)
	}

	if len(result.Choices) == 0 {
		return "", fmt.Errorf("no response content")
	}

	return result.Choices[0].Message.Content, nil
}

func (s *DeepSeekService) mockResponse(userMessage string) string {
	return fmt.Sprintf(`【围棋老师讲解】

📖 棋理分析：
这步棋体现了基础的围棋原则。在围棋中，每一步都需要考虑：
1. 棋子的效率 - 是否发挥了最大价值
2. 厚薄关系 - 自己的棋形是否扎实
3. 全局平衡 - 是否符合大场的选择

💡 学习要点：
• 布局阶段优先抢占大场
• 注意棋形的完整，避免出现愚形
• 时刻关注双方的厚薄对比

📝 建议：
继续保持思考的习惯，多分析每步棋的目的和意义。随着练习增多，你对局面的判断会越来越准确！

---
注：当前为演示模式，配置 DEEPSEEK_API_KEY 后将接入真实 AI 讲解。`)
}
