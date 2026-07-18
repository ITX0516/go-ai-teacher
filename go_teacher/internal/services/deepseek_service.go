package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"go_teacher/internal/models"
	"net/http"
)

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
	prompt := fmt.Sprintf(`你是一位专业的围棋老师，请用通俗易懂的语言讲解这步棋。

背景信息：
- 第 %d 手棋
- 落子位置：%s
- 胜率变化：%+.2f%%
- 当前局面：%s

请从以下几个方面讲解（用中文回答）：
1. 这步棋的意图和目的
2. 这步棋的质量评价（好棋/疑问手/恶手）及原因
3. 有没有更好的下法建议
4. 对于初学者的棋理提示

请用友好、鼓励的语气，就像一位耐心的围棋老师在讲解。`, moveNumber, move, winRateChange, gameContext)

	response, err := s.chat(prompt)
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
	prompt := fmt.Sprintf(`你是一位专业的围棋老师。以下是当前棋局的SGF棋谱：
%s

用户的问题：%s

请用通俗易懂的中文回答，结合具体的棋理进行讲解。如果涉及到具体的棋子位置，请用坐标说明（如：黑棋在D4位）。`, gameSGF, userQuestion)

	return s.chat(prompt)
}

func (s *DeepSeekService) AnalyzeGameSummary(sgf string, result string) (string, error) {
	prompt := fmt.Sprintf(`你是一位专业的围棋老师，请对下面这盘棋做一个整体复盘总结。

棋谱SGF：
%s

结果：%s

请从以下几个方面分析（用中文回答）：
1. 本局的关键转折点
2. 优势方是如何建立和保持优势的
3. 劣势方有哪些可以改进的地方
4. 全局的棋理要点总结
5. 给对局者的建议

请用友好、鼓励的语气，结构清晰。`, sgf, result)

	return s.chat(prompt)
}

func (s *DeepSeekService) GeneratePuzzleExplanation(puzzle *models.Puzzle, isCorrect bool, userMove string) (string, error) {
	prompt := fmt.Sprintf(`你是一位耐心的围棋死活题老师。

题目：%s
难度：%s
描述：%s
正确答案序列：%v

用户走了：%s
是否正确：%v

请给用户讲解这道题（用中文，友好鼓励的语气）：
1. 解释用户这步棋的问题或亮点
2. 讲解正确的解题思路
3. 涉及的棋理和技巧
4. 举一反三的提示`, puzzle.Title, puzzle.Difficulty, puzzle.Description, puzzle.CorrectMoves, userMove, isCorrect)

	return s.chat(prompt)
}

func (s *DeepSeekService) chat(userMessage string) (string, error) {
	if s.apiKey == "" {
		return s.mockResponse(userMessage), nil
	}

	reqBody := deepseekRequest{
		Model:  "deepseek-chat",
		Stream: false,
		Messages: []deepseekMessage{
			{Role: "system", Content: "你是一位专业的围棋老师，精通围棋棋理、死活、定式、布局、中盘、官子等各方面知识。你擅长用通俗易懂的语言讲解复杂的围棋概念，语气友好、耐心、鼓励。"},
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
