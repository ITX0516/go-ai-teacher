package services

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"go_teacher/internal/config"
	"go_teacher/internal/models"
	"log"
	"math"
	"math/rand"
	"os/exec"
	"time"
)

type MoveRecord struct {
	X     int    `json:"x"`
	Y     int    `json:"y"`
	Color int    `json:"color"`
	Move  string `json:"move"`
}

type AnalysisResult struct {
	Winrate        float64        `json:"winrate"`
	BestMove       string         `json:"bestMove"`
	ScoreLead      float64        `json:"scoreLead"`
	CandidateMoves []CandidateMove `json:"candidateMoves"`
}

type CandidateMove struct {
	Move     string  `json:"move"`
	Winrate  float64 `json:"winrate"`
	ScoreLead float64 `json:"scoreLead"`
}

type KataGoRequest struct {
	ID            string       `json:"id"`
	InitialStones [][]string   `json:"initialStones"`
	Moves         [][]string   `json:"moves"`
	Rules         string       `json:"rules"`
	BoardXSize    int          `json:"boardXSize"`
	BoardYSize    int          `json:"boardYSize"`
	AnalyzeTurns  []int        `json:"analyzeTurns"`
}

type KataGoResponse struct {
	ID      string             `json:"id"`
	Results []AnalysisTurnResult `json:"results"`
}

type AnalysisTurnResult struct {
	TurnIndex int             `json:"turnIndex"`
	RootInfo  RootInfo        `json:"rootInfo"`
	MoveInfos []MoveInfo      `json:"moveInfos"`
}

type RootInfo struct {
	Winrate   float64 `json:"winrate"`
	ScoreLead float64 `json:"scoreLead"`
}

type MoveInfo struct {
	Move      string  `json:"move"`
	Winrate   float64 `json:"winrate"`
	ScoreLead float64 `json:"scoreLead"`
}

type KataGoService struct {
	cfg     config.KataGoConfig
	enabled bool
}

func NewKataGoService(cfg config.KataGoConfig) *KataGoService {
	return &KataGoService{
		cfg:     cfg,
		enabled: true,
	}
}

func (s *KataGoService) Analyze(moves []MoveRecord, boardSize int, color int) (*AnalysisResult, error) {
	if !s.enabled {
		return s.mockAnalysis(len(moves)), nil
	}

	kataMoves := make([][]string, 0)
	for _, m := range moves {
		c := "B"
		if m.Color == 2 {
			c = "W"
		}
		kataMoves = append(kataMoves, []string{c, m.Move})
	}

	request := KataGoRequest{
		ID:            "analyze-1",
		InitialStones: [][]string{},
		Moves:         kataMoves,
		Rules:         "tromp-taylor",
		BoardXSize:    boardSize,
		BoardYSize:    boardSize,
		AnalyzeTurns:  []int{len(moves)},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, s.cfg.ExecutablePath,
		"analysis",
		"-model", s.cfg.ModelPath,
		"-config", s.cfg.ConfigPath,
		"-override-config", fmt.Sprintf("maxVisits=%d", s.cfg.MaxVisits),
		"-override-config", fmt.Sprintf("numAnalysisThreads=%d", s.cfg.NumAnalysisThreads),
		"-override-config", fmt.Sprintf("nnMaxBatchSize=%d", s.cfg.NNMaxBatchSize),
	)

	stdinPipe, err := cmd.StdinPipe()
	if err != nil {
		log.Printf("[KataGo] 创建 stdin 管道失败: %v", err)
		return s.mockAnalysis(len(moves)), nil
	}

	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		log.Printf("[KataGo] 创建 stdout 管道失败: %v", err)
		return s.mockAnalysis(len(moves)), nil
	}

	if err := cmd.Start(); err != nil {
		log.Printf("[KataGo] 启动子进程失败: %v", err)
		return s.mockAnalysis(len(moves)), nil
	}

	encoder := json.NewEncoder(stdinPipe)
	if err := encoder.Encode(request); err != nil {
		log.Printf("[KataGo] 写入 JSON 请求失败: %v", err)
		_ = cmd.Process.Kill()
		return s.mockAnalysis(len(moves)), nil
	}

	if err := stdinPipe.Close(); err != nil {
		log.Printf("[KataGo] 关闭 stdin 失败: %v", err)
	}

	scanner := bufio.NewScanner(stdoutPipe)
	var responseLine string
	for scanner.Scan() {
		responseLine = scanner.Text()
		if responseLine != "" {
			break
		}
	}

	if err := scanner.Err(); err != nil {
		log.Printf("[KataGo] 读取响应失败: %v", err)
		_ = cmd.Process.Kill()
		return s.mockAnalysis(len(moves)), nil
	}

	if err := cmd.Wait(); err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			log.Printf("[KataGo] 分析超时")
			return s.mockAnalysis(len(moves)), nil
		}
		log.Printf("[KataGo] 子进程退出异常: %v", err)
	}

	if responseLine == "" {
		log.Println("[KataGo] 响应为空")
		return s.mockAnalysis(len(moves)), nil
	}

	var resp KataGoResponse
	if err := json.Unmarshal([]byte(responseLine), &resp); err != nil {
		log.Printf("[KataGo] 解析 JSON 响应失败: %v, response: %s", err, responseLine)
		return s.mockAnalysis(len(moves)), nil
	}

	if len(resp.Results) == 0 {
		log.Println("[KataGo] 无分析结果")
		return s.mockAnalysis(len(moves)), nil
	}

	result := resp.Results[0]
	candidates := make([]CandidateMove, 0)
	for _, mi := range result.MoveInfos {
		candidates = append(candidates, CandidateMove{
			Move:     mi.Move,
			Winrate:  mi.Winrate,
			ScoreLead: mi.ScoreLead,
		})
	}

	bestMove := ""
	if len(result.MoveInfos) > 0 {
		bestMove = result.MoveInfos[0].Move
	}

	return &AnalysisResult{
		Winrate:        result.RootInfo.Winrate,
		BestMove:       bestMove,
		ScoreLead:      result.RootInfo.ScoreLead,
		CandidateMoves: candidates,
	}, nil
}

func (s *KataGoService) GenMove(moves []MoveRecord, boardSize int, color int) (string, error) {
	result, err := s.Analyze(moves, boardSize, color)
	if err != nil {
		return "pass", err
	}
	if result.BestMove == "" || result.BestMove == "pass" {
		return "pass", nil
	}
	return result.BestMove, nil
}

func (s *KataGoService) Close() error {
	return nil
}

func (s *KataGoService) mockAnalysis(moveCount int) *AnalysisResult {
	baseWinRate := 0.5
	if moveCount > 0 {
		baseWinRate = 0.5 + math.Sin(float64(moveCount)*0.3)*0.1
	}

	candidates := []CandidateMove{
		{Move: "D17", Winrate: baseWinRate, ScoreLead: -0.08},
		{Move: "R4", Winrate: baseWinRate - 0.005, ScoreLead: -0.1},
		{Move: "Q16", Winrate: baseWinRate - 0.01, ScoreLead: -0.15},
		{Move: "D4", Winrate: baseWinRate - 0.015, ScoreLead: -0.2},
	}

	return &AnalysisResult{
		Winrate:        baseWinRate,
		BestMove:       candidates[0].Move,
		ScoreLead:      candidates[0].ScoreLead,
		CandidateMoves: candidates,
	}
}

func (s *KataGoService) AnalyzePosition(game *models.GameState) (*models.AnalysisResult, error) {
	if !s.enabled {
		return s.mockModelsAnalysis(game), nil
	}

	moves := make([]MoveRecord, 0)
	for _, m := range game.Moves {
		moves = append(moves, MoveRecord{
			X:     m.X,
			Y:     m.Y,
			Color: int(m.Color),
			Move:  m.Move,
		})
	}

	color := 1
	if game.Current == models.White {
		color = 2
	}

	result, err := s.Analyze(moves, game.BoardSize, color)
	if err != nil {
		return s.mockModelsAnalysis(game), nil
	}

	topMoves := make([]models.TopMove, 0)
	for _, cm := range result.CandidateMoves {
		topMoves = append(topMoves, models.TopMove{
			Move:      cm.Move,
			WinRate:   cm.Winrate * 100,
			ScoreLead: cm.ScoreLead,
			Visits:    1000,
			Policy:    0.3,
		})
	}

	return &models.AnalysisResult{
		WinRate:    result.Winrate * 100,
		ScoreLead:  result.ScoreLead,
		TopMoves:   topMoves,
		MoveNumber: len(game.Moves),
	}, nil
}

func (s *KataGoService) GetBestMove(game *models.GameState, difficulty string) (string, error) {
	analysis, err := s.AnalyzePosition(game)
	if err != nil {
		return "", err
	}

	switch difficulty {
	case "easy":
		return s.pickEasyMove(analysis), nil
	case "medium":
		return s.pickMediumMove(analysis), nil
	case "hard":
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[0].Move, nil
		}
	default:
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[0].Move, nil
		}
	}
	return "pass", nil
}

func (s *KataGoService) pickEasyMove(analysis *models.AnalysisResult) string {
	if len(analysis.TopMoves) < 3 {
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[len(analysis.TopMoves)-1].Move
		}
		return "pass"
	}
	idx := min(2+rand.Intn(3), len(analysis.TopMoves)-1)
	return analysis.TopMoves[idx].Move
}

func (s *KataGoService) pickMediumMove(analysis *models.AnalysisResult) string {
	if len(analysis.TopMoves) < 2 {
		if len(analysis.TopMoves) > 0 {
			return analysis.TopMoves[0].Move
		}
		return "pass"
	}
	idx := rand.Intn(2)
	return analysis.TopMoves[idx].Move
}

func (s *KataGoService) mockModelsAnalysis(game *models.GameState) *models.AnalysisResult {
	moveNum := len(game.Moves)
	baseWinRate := 50.0
	if moveNum > 0 {
		baseWinRate = 50 + math.Sin(float64(moveNum)*0.3)*10
	}

	topMoves := make([]models.TopMove, 0)
	candidates := generateCandidateMoves(game)
	for i, move := range candidates {
		if i >= 5 {
			break
		}
		wrDiff := float64(5 - i)
		topMoves = append(topMoves, models.TopMove{
			Move:      move,
			WinRate:   baseWinRate - wrDiff + rand.Float64()*2,
			ScoreLead: 0.5 + float64(5-i)*0.8,
			Visits:    1000 - i*150 + rand.Intn(100),
			Policy:    0.3 - float64(i)*0.05,
		})
	}

	return &models.AnalysisResult{
		WinRate:    baseWinRate,
		ScoreLead:  1.5,
		TopMoves:   topMoves,
		MoveNumber: moveNum,
	}
}

func generateCandidateMoves(game *models.GameState) []string {
	moves := []string{
		"Q16", "D4", "D16", "Q4",
		"R14", "C14", "C4", "R4",
		"K4", "K16", "D10", "Q10",
		"E4", "E16", "P4", "P16",
		"F3", "F17", "O3", "O17",
	}
	result := make([]string, 0)
	used := make(map[string]bool)
	for _, m := range game.Moves {
		used[m.Move] = true
	}
	for _, m := range moves {
		if !used[m] {
			result = append(result, m)
		}
	}
	if len(result) == 0 {
		result = append(result, "T10")
	}
	return result
}

func MoveToCoord(move string, boardSize int) (int, int, error) {
	if move == "pass" || move == "tt" {
		return -1, -1, nil
	}
	if len(move) < 2 {
		return 0, 0, fmt.Errorf("invalid move format: %s", move)
	}
	letter := rune(move[0])
	x := int(letter - 'A')
	if letter > 'I' {
		x--
	}
	yStr := move[1:]
	var y int
	fmt.Sscanf(yStr, "%d", &y)
	y = boardSize - y
	if x < 0 || x >= boardSize || y < 0 || y >= boardSize {
		return 0, 0, fmt.Errorf("move out of bounds: %s", move)
	}
	return x, y, nil
}

func AnalysisToJSON(a *models.AnalysisResult) []byte {
	b, _ := json.Marshal(a)
	return b
}