package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"go_teacher/internal/models"
	"io"
	"log"
	"net/http"
	"strings"
)

const systemPromptExplainMove = `你是一位资深围棋老师，正在和学生面对面复盘。我会给你完整的 SGF 棋谱。请像真人一样自然说话，简洁、有画面感。不要长篇大论，除非学生要求详细说。不要套模板，像微信聊天一样自由回答。`

const systemPromptExplainPosition = `你是一位资深围棋老师，正在和学生面对面复盘。我会给你完整的 SGF 棋谱。请像真人一样自然说话，简洁、有画面感。不要长篇大论，除非学生要求详细说。不要套模板，像微信聊天一样自由回答。`

const systemPromptAnalyzeSummary = `你是一位资深围棋老师，正在和学生面对面复盘。我会给你完整的 SGF 棋谱。请像真人一样自然说话，简洁、有画面感。不要长篇大论，除非学生要求详细说。不要套模板，像微信聊天一样自由回答。`

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
	Model       string             `json:"model"`
	Messages    []deepseekMessage  `json:"messages"`
	Stream      bool               `json:"stream"`
	Temperature float64            `json:"temperature,omitempty"`
	MaxTokens   int                `json:"max_tokens,omitempty"`
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

// MoveAnalysisData 用于传递 KataGo 分析数据
type MoveAnalysisData struct {
	WinRate       float64
	ScoreLead     float64
	WinRateChange float64
	MoveNumber    int
	CurrentTurn   string
}

// AreaDescription 关键区域描述
type AreaDescription struct {
	Location string
	Desc     string
}

func (s *DeepSeekService) ExplainMove(move string, moveNumber int, winRateChange float64, gameSGF string, analysis *MoveAnalysisData, areas []AreaDescription) (*models.Explanation, error) {
	// 构建关键区域文字描述
	areaText := ""
	if len(areas) > 0 {
		areaText = "【关键区域文字描述】\n"
		for _, a := range areas {
			areaText += fmt.Sprintf("- %s：%s\n", a.Location, a.Desc)
		}
	}

	// 构建 KataGo 分析数据
	analysisText := ""
	if analysis != nil {
		analysisText = fmt.Sprintf(`【KataGo 分析数据】
- 当前胜率：%s %.1f%%
- 这手棋导致胜率变化：%+.1f%%
- 目差：%s %.1f 目`, analysis.CurrentTurn, analysis.WinRate, analysis.WinRateChange, analysis.CurrentTurn, analysis.ScoreLead)
	}

	userPrompt := fmt.Sprintf(`【棋局信息】
棋盘大小：19路
当前手数：第 %d 手
轮到：%s

【SGF 棋谱】
%s

%s

%s

【用户问题】
请分析第%d手 %s 的问题。`, moveNumber, analysis.CurrentTurn, gameSGF, areaText, analysisText, moveNumber, move)

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
	systemPrompt := `你是一位资深围棋老师，正在和学生面对面讲解题目。请像真人一样自然说话，简洁、有画面感。不要长篇大论，不要套模板，像微信聊天一样自由回答。`

	userPrompt := fmt.Sprintf(`题目：%s
难度：%s
描述：%s
正确答案序列：%v

用户走了：%s
是否正确：%v

请讲解这道题：先说用户这步棋的问题或亮点，再讲解正确思路。`, puzzle.Title, puzzle.Difficulty, puzzle.Description, puzzle.CorrectMoves, userMove, isCorrect)

	return s.chat(systemPrompt, userPrompt)
}

// KataGoChatData KataGo 数据传递给 DeepSeek（用于自然语言化）
type KataGoChatData struct {
	MoveNumber     int     `json:"moveNumber"`
	Winrate        float64 `json:"winrate"`         // 0~1
	WinrateChange  float64 `json:"winrateChange"`   // 0~1
	BestMove       string  `json:"bestMove"`        // 如 "D4"
	ScoreLead      float64 `json:"scoreLead"`       // 正数 = 黑领先，负数 = 白领先
	CurrentPlayer  string  `json:"currentPlayer"`   // "black" | "white"
	CandidateMoves []struct {
		Move    string  `json:"move"`
		Winrate float64 `json:"winrate"`
	} `json:"candidateMoves,omitempty"`
}

// HistoryMessage 多轮对话历史
type HistoryMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// ChatWithHistory 支持多轮对话历史 + KataGo 数据的聊天接口
// Prompt 裸奔：System Prompt 留空让模型自由发挥
func (s *DeepSeekService) ChatWithHistory(sgf, question string, history []HistoryMessage, kataGoData *KataGoChatData) (string, error) {
	// 用户消息：直接拼接 SGF + KataGo 自然语言 + 问题，不要任何【】标签
	var sb bytes.Buffer
	sb.WriteString(sgf)
	sb.WriteString("\n\n")

	if kataGoData != nil {
		kataText := kataGoDataToNaturalLanguage(kataGoData)
		log.Printf("[DeepSeek] kataGoNatural=%q", kataText)
		sb.WriteString(kataText)
		sb.WriteString("\n\n")
	}

	sb.WriteString(question)

	userMsg := sb.String()
	log.Printf("[DeepSeek] finalUserPrompt (first 500 chars): %.500s", userMsg)

	return s.chatWithRawPrompt("", userMsg, history)
}

// kataGoDataToNaturalLanguage 把 KataGo 数据转为自然语言
func kataGoDataToNaturalLanguage(d *KataGoChatData) string {
	var sb strings.Builder

	// 胜率
	if d.Winrate > 0 {
		blackWR := d.Winrate * 100
		whiteWR := 100 - blackWR
		fmt.Fprintf(&sb, "胜率：黑%.0f%% 白%.0f%%\n", blackWR, whiteWR)
	}

	// 胜率变化
	if d.WinrateChange != 0 {
		fmt.Fprintf(&sb, "这手导致胜率变化：%+.0f%%\n", d.WinrateChange*100)
	}

	// AI推荐下一手
	if d.BestMove != "" {
		fmt.Fprintf(&sb, "AI推荐：%s\n", d.BestMove)
	}

	// 目差
	if d.ScoreLead != 0 {
		if d.ScoreLead > 0 {
			fmt.Fprintf(&sb, "目差：黑领先%.1f目\n", d.ScoreLead)
		} else {
			fmt.Fprintf(&sb, "目差：白领先%.1f目\n", -d.ScoreLead)
		}
	}

	// 候选点
	if len(d.CandidateMoves) > 0 {
		sb.WriteString("候选点：")
		for i, cm := range d.CandidateMoves {
			if i >= 3 {
				break
			}
			fmt.Fprintf(&sb, "%s(%.0f%%) ", cm.Move, cm.Winrate*100)
		}
		sb.WriteString("\n")
	}

	return strings.TrimRight(sb.String(), "\n")
}

func (s *DeepSeekService) chat(systemPrompt, userMessage string) (string, error) {
	return s.chatWithHistory(systemPrompt, userMessage, nil)
}

func (s *DeepSeekService) chatWithHistory(systemPrompt, userMessage string, history []HistoryMessage) (string, error) {
	return s.chatWithRawPrompt(systemPrompt, userMessage, history)
}

// chatWithRawPrompt 底层调用 DeepSeek API，温度 0.9，max_tokens 2000
func (s *DeepSeekService) chatWithRawPrompt(systemPrompt, userMessage string, history []HistoryMessage) (string, error) {
	if s.apiKey == "" {
		return s.mockResponse(userMessage), nil
	}

	messages := []deepseekMessage{}
	if systemPrompt != "" {
		messages = append(messages, deepseekMessage{Role: "system", Content: systemPrompt})
	}
	for _, h := range history {
		messages = append(messages, deepseekMessage{Role: h.Role, Content: h.Content})
	}
	messages = append(messages, deepseekMessage{Role: "user", Content: userMessage})

	reqBody := deepseekRequest{
		Model:       "deepseek-chat",
		Stream:      false,
		Messages:    messages,
		Temperature: 0.9,
		MaxTokens:   2000,
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
