package services

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"go_teacher/internal/config"
	"log"
	"os/exec"
	"time"
)

type AnalysisResult struct {
	Winrate        float64         `json:"winrate"`
	BestMove       string          `json:"bestMove"`
	ScoreLead      float64         `json:"scoreLead"`
	CandidateMoves []CandidateMove `json:"candidateMoves,omitempty"`
}

type CandidateMove struct {
	Move      string  `json:"move"`
	Winrate   float64 `json:"winrate"`
	ScoreLead float64 `json:"scoreLead"`
	Visits    int     `json:"visits"`
}

type MoveInput struct {
	X     int    `json:"x"`
	Y     int    `json:"y"`
	Color int    `json:"color"`
	Move  string `json:"move"`
}

type KataGoService struct {
	cfg     config.KataGoConfig
	enabled bool
}

func NewKataGoService(cfg config.KataGoConfig) *KataGoService {
	s := &KataGoService{cfg: cfg, enabled: true}
	log.Printf("[KataGo] 配置加载: exe=%s, model=%s, visits=%d", cfg.ExecutablePath, cfg.ModelPath, cfg.MaxVisits)
	return s
}

func (s *KataGoService) Analyze(moves []MoveInput, boardSize int, color int) (*AnalysisResult, error) {
	if !s.enabled {
		return s.mockResult(), nil
	}

	kgMoves := make([][]string, 0, len(moves))
	for _, m := range moves {
		c := "B"
		if m.Color == 2 {
			c = "W"
		}
		moveStr := m.Move
		if moveStr == "" && m.X >= 0 && m.Y >= 0 {
			moveStr = coordToGTP(m.X, m.Y, boardSize)
		}
		kgMoves = append(kgMoves, []string{c, moveStr})
	}

	req := map[string]interface{}{
		"id":            "analyze",
		"initialStones": []interface{}{},
		"moves":         kgMoves,
		"rules":         "tromp-taylor",
		"boardXSize":    boardSize,
		"boardYSize":    boardSize,
		"analyzeTurns":  []int{len(moves)},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	result, err := s.runAnalysis(ctx, req)
	if err != nil {
		log.Printf("[KataGo] 分析失败，降级 mock: %v", err)
		return s.mockResult(), nil
	}

	return result, nil
}

func (s *KataGoService) GenMove(moves []MoveInput, boardSize int, color int) (string, error) {
	res, err := s.Analyze(moves, boardSize, color)
	if err != nil || res == nil || res.BestMove == "" {
		return "pass", nil
	}
	return res.BestMove, nil
}

func (s *KataGoService) runAnalysis(ctx context.Context, req map[string]interface{}) (*AnalysisResult, error) {
	args := []string{
		"analysis",
		"-model", s.cfg.ModelPath,
		"-config", s.cfg.ConfigPath,
		"-override-config", fmt.Sprintf("maxVisits=%d", s.cfg.MaxVisits),
		"-override-config", fmt.Sprintf("numAnalysisThreads=%d", s.cfg.NumAnalysisThreads),
		"-override-config", fmt.Sprintf("nnMaxBatchSize=%d", s.cfg.NNMaxBatchSize),
	}

	cmd := exec.CommandContext(ctx, s.cfg.ExecutablePath, args...)

	stdin, err := cmd.StdinPipe()
	if err != nil {
		return nil, fmt.Errorf("stdin pipe: %w", err)
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, fmt.Errorf("stdout pipe: %w", err)
	}

	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("start katago: %w", err)
	}

	if err := json.NewEncoder(stdin).Encode(req); err != nil {
		stdin.Close()
		return nil, fmt.Errorf("encode request: %w", err)
	}
	stdin.Close()

	scanner := bufio.NewScanner(stdout)
	if !scanner.Scan() {
		cmd.Wait()
		return nil, fmt.Errorf("no output from katago")
	}
	line := scanner.Text()

	if err := cmd.Wait(); err != nil {
		if ctx.Err() != nil {
			return nil, fmt.Errorf("katago timeout: %w", ctx.Err())
		}
	}

	var resp struct {
		RootInfo struct {
			Winrate   float64 `json:"winrate"`
			ScoreLead float64 `json:"scoreLead"`
		} `json:"rootInfo"`
		MoveInfos []struct {
			Move      string  `json:"move"`
			Winrate   float64 `json:"winrate"`
			ScoreLead float64 `json:"scoreLead"`
			Visits    int     `json:"visits"`
		} `json:"moveInfos"`
	}

	if err := json.Unmarshal([]byte(line), &resp); err != nil {
		return nil, fmt.Errorf("parse response: %w, raw=%s", err, line)
	}

	result := &AnalysisResult{
		Winrate:   resp.RootInfo.Winrate,
		ScoreLead: resp.RootInfo.ScoreLead,
	}

	if len(resp.MoveInfos) > 0 {
		result.BestMove = resp.MoveInfos[0].Move
		for _, m := range resp.MoveInfos {
			result.CandidateMoves = append(result.CandidateMoves, CandidateMove{
				Move:      m.Move,
				Winrate:   m.Winrate,
				ScoreLead: m.ScoreLead,
				Visits:    m.Visits,
			})
		}
	}

	return result, nil
}

func (s *KataGoService) Close() {
	log.Println("[KataGo] service closed")
}

func (s *KataGoService) mockResult() *AnalysisResult {
	return &AnalysisResult{
		Winrate:   0.5,
		BestMove:  "D4",
		ScoreLead: 0,
		CandidateMoves: []CandidateMove{
			{Move: "D4", Winrate: 0.5, ScoreLead: 0, Visits: 20},
		},
	}
}

func coordToGTP(x, y, boardSize int) string {
	letters := "ABCDEFGHJKLMNOPQRST"
	if x < 0 || x >= len(letters) {
		return "pass"
	}
	gtpY := boardSize - y
	return fmt.Sprintf("%c%d", letters[x], gtpY)
}
