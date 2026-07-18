package services

import (
	"encoding/json"
	"fmt"
	"go_teacher/internal/models"
	"math"
	"math/rand"
)

type KataGoService struct {
	enabled bool
}

func NewKataGoService(enabled bool) *KataGoService {
	return &KataGoService{enabled: enabled}
}

func (s *KataGoService) AnalyzePosition(game *models.GameState) (*models.AnalysisResult, error) {
	if !s.enabled {
		return s.mockAnalysis(game), nil
	}
	return s.mockAnalysis(game), nil
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

func (s *KataGoService) mockAnalysis(game *models.GameState) *models.AnalysisResult {
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
